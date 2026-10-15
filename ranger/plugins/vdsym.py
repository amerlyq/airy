"""vdsym: VD symlink search / replacement, centered around ONE shared directory cache.

Layout (the rest of the former vdsym.py lives in sibling plugins):
- _Cache      process-wide directory cache + per-roots search views (shared by :vdsym and by the
              link scans of vdguard / vddangling; survives module re-exec)
- vdsym       the command
- find_hits / find_backlinks / make_dashboard      reusable helpers
- HOOKS       preflight / cd / warm callbacks other plugins register (hook())
- cd signal   lazy cache warm-up on the first cd() into a VD root, "visited" dir bookkeeping

Siblings: vdconf (settings)  vdutil (symlink/fs helpers)  pasteflow (generic paste wrapper)
          vdguard (clip + symlink guards for cut / paste / rename / delete)
          vddangling (links that dangle behind ranger's back)
"""

from __future__ import annotations

import hashlib
import logging
import os
import re
import subprocess
import sys
import threading
import time
import types
from collections.abc import Iterable, Sequence
from concurrent.futures import ThreadPoolExecutor
from fnmatch import fnmatchcase
from fnmatch import translate as glob_translate
from os import path as fs
from typing import NamedTuple

from ranger.api.commands import Command
from ranger.ext.shell_escape import shell_quote

try:  # ranger imports plugins as `plugins.<name>` with the confdir on sys.path
    from plugins import rhooks
    from plugins import vdconf as C
    from plugins.vdutil import _gone, _hops, _norm, _safe_readlink, replace_link
except ImportError:  # fallback: the plugin files somewhere on PYTHONPATH
    import rhooks
    import vdconf as C
    from vdutil import _gone, _hops, _norm, _safe_readlink, replace_link

_LOG = logging.getLogger("ranger.vdsym")


# --------------------------------------------------------------------------- #
# hooks other VD plugins register (kept in rhooks.shared: survive a re-exec of this module)
#   preflight  fn(cmd, flags, proceed)   before :vdsym runs (vddangling)
#   cd         fn(path)                  cd() into a VD root
#   warm       fn()                      end of the background cache warm-up
# --------------------------------------------------------------------------- #

HOOKS = rhooks.shared("vdsym.hooks", lambda: {"preflight": {}, "cd": {}, "warm": {}})
_ROTATIONS = rhooks.shared("vdsym.rotations", dict)


def hook(kind: str, key: str, fn) -> None:
    HOOKS[kind][key] = fn  # same key replaces: re-exec safe


_NUMERIC = re.compile(r"(\d+)-0*(\d+)")


_LONG_FLAGS = {
    "autojump1": "a",
    "basename": "b",
    "clipboard": "c",
    "dashboard": "d",
    "glob": "g",
    "ignore-case": "i",
    "jump": "j",
    "links-only": "l",
    "multiple": "m",
    "numeric": "n",
    "open": "o",
    "print": "p",
    "replace": "R",
    "refresh": "q",
    "rescan": "Q",
    "selection": "s",
    "view": "v",
    "norefresh": "N",
    "xclip": "x",
    "yanked": "y",
}


_GROUPS = {
    "action": {
        "dashboard": "d",
        "jump": "j",
        "autojump1": "a",
        "open": "o",
        "print": "p",
        "replace": "R",
        "rotate": "r",
        "xclip": "x",
        "refresh": "q",
        "rescan": "Q",
    },
    "source": {
        "basename": "b",
        "clipboard": "c",
        "selection": "s",
        "yanked": "y",
    },
    "target": {"clipboard": "c", "yanked": "y", "selection": "s"},
    "modifiers": {
        "glob": "g",
        "numeric": "n",
        "ignore-case": "i",
        "links-only": "l",
        "view": "v",
        "norefresh": "N",
    },
}


# --------------------------------------------------------------------------- #
# scan records
# --------------------------------------------------------------------------- #


class _Dir(NamedTuple):
    mtime: int
    entries: list[str]  # indexed paths: files, links and subdirectories
    lazy: list[str]  # [directory] for an unlisted pics dir, else []
    subdirs: list[str]  # real subdirectories to descend into
    links: dict[str, str]  # symlink path -> readlink() for symlinks in `entries`
    racy: bool = (
        False  # mtime too close to scan time to be trusted: re-read next validation
    )


_DNUM_DIR = re.compile(r"(\d+)(?:-.*)?", re.S)


def _pics_dnum(directory: str) -> str | None:
    """'<dnum>' of a '<dnum>' / '<dnum>-*' directory sitting under a pics parent, else None."""
    match = _DNUM_DIR.fullmatch(fs.basename(directory))
    if match and any(
        fnmatchcase(fs.basename(fs.dirname(directory)), pattern)
        for pattern in C.PICS_PARENTS
    ):
        return match[1]
    return None


def _same_content(a: _Dir, b: _Dir) -> bool:
    return (
        a.entries == b.entries
        and a.subdirs == b.subdirs
        and a.lazy == b.lazy
        and a.links == b.links
    )


def _make_rec(
    directory: str,
    root: str,
    mtime: int,
    items: Iterable[tuple[str, bool, str | None]],
    since: int | None = None,
) -> _Dir:
    """`since`: when the listing the items come from was started; a directory modified after
    that may have changed between fd's separate runs, so it is re-read at the next validation."""
    racy = time.time_ns() - mtime < C.RACY_NS or (since is not None and mtime >= since)
    if _pics_dnum(directory) is not None:
        return _Dir(mtime, [], [directory], [], {}, racy)
    entries: list[str] = []
    subdirs: list[str] = []
    links: dict[str, str] = {}
    for path, is_dir, target in items:
        entries.append(path)
        if is_dir:
            subdirs.append(path)
        elif target is not None:
            links[path] = target
    return _Dir(mtime, entries, [], subdirs, links, racy)


def _scan_dir(directory: str, root: str, mtime: int | None = None) -> _Dir | None:
    try:
        if mtime is None:
            mtime = os.stat(directory).st_mtime_ns
        if _pics_dnum(directory) is not None:
            return _make_rec(directory, root, mtime, ())
        items = []
        with os.scandir(directory) as it:
            for entry in it:
                target = None
                if entry.is_symlink():
                    target = _safe_readlink(entry.path) or ""
                items.append((entry.path, entry.is_dir(follow_symlinks=False), target))
    except OSError:
        return None
    return _make_rec(directory, root, mtime, items)


# --------------------------------------------------------------------------- #
# search index
# --------------------------------------------------------------------------- #


class _Index:
    """basename -> paths; a symlink is also filed under its target's basename."""

    def __init__(self) -> None:
        self.names: dict[str, list[str]] = {}
        self.links: set[str] = set()
        self.targets: dict[str, str] = {}
        self._ci: dict[str, list[str]] | None = None

    def add(self, path: str, target: str | None = None) -> None:
        self.names.setdefault(fs.basename(path), []).append(path)
        if target is not None:
            self.link(path, target)

    def link(self, path: str, target: str) -> None:
        self.links.add(path)
        self.targets[path] = target
        base = fs.basename(target.rstrip("/"))
        if base:
            self.names.setdefault(base, []).append(path)

    def table(self, icase: bool) -> dict[str, list[str]]:
        if not icase:
            return self.names
        if self._ci is None:
            merged: dict[str, list[str]] = {}
            for key, values in self.names.items():
                merged.setdefault(key.casefold(), []).extend(values)
            self._ci = merged
        return self._ci

    def find(self, needle: str, glob: bool, icase: bool) -> Iterable[str]:
        table = self.table(icase)
        if not glob:
            return table.get(needle, ())
        if any(char in needle for char in "*?["):
            test = re.compile(glob_translate(f"*{needle}*")).match
        else:
            test = lambda key: needle in key  # noqa: E731
        return [path for key, values in table.items() if test(key) for path in values]


class _View:
    """Index over one tuple of roots, valid for the given per-root versions."""

    def __init__(
        self,
        versions: tuple[int, ...],
        index: _Index,
        pics_dirs: dict[str, list[str]],
        count: int,
    ) -> None:
        self.versions = versions
        self.index = index
        self.pics_dirs = pics_dirs
        self.count = count


class _Cache:
    """Directory records per root, validated by directory mtime; views per roots tuple."""

    def __init__(self, stamp: str) -> None:
        self.stamp = stamp
        self.lock = threading.RLock()
        self.dirs: dict[str, dict[str, _Dir]] = {}
        self.rootver: dict[str, int] = {}
        self.views: dict[tuple, _View] = {}
        self.visited: set[str] = (
            set()
        )  # dirs seen by cd() / targeted by dashboards since last seek
        self.unreadable: set[str] = (
            set()
        )  # dirs that could not be listed: results may be incomplete
        self.reported_unreadable: frozenset[str] = frozenset()
        self.warmed = False
        ## MOVED: self.fm -> rhooks.fm(); self.monitor -> vddangling (_mon)

    def _bump(self, root: str) -> None:
        self.rootver[root] = self.rootver.get(root, 0) + 1

    def ensure(
        self, roots: Iterable[str], mode: str = "none", kind: str = "all"
    ) -> _View:
        """mode: none (build if missing), visited (+ rescan dirs visited since last seek),
        validate (+ stat-walk everything, rescan changed dirs), rescan (rebuild from scratch).
        kind: "all" (every path) or "links" (symlinks only: small, for backlink lookups)."""
        roots = tuple(roots)
        with self.lock:
            if mode == "rescan":
                self.visited.clear()
                self._prefill(roots)
            else:
                missing = [root for root in roots if root not in self.dirs]
                self._prefill(missing)
                if mode == "validate":
                    self.visited.clear()
                    for root in roots:
                        if root in self.dirs and root not in missing:
                            self._refresh(root)
                elif mode == "visited":
                    self._flush_visited(roots)
            versions = tuple(self.rootver.get(root, 0) for root in roots)
            view = self.views.get((roots, kind))
            if view is None or view.versions != versions:
                view = self.views[(roots, kind)] = self._build(roots, versions, kind)
            return view

    # -- building ----------------------------------------------------------- #

    def _build(
        self, roots: tuple[str, ...], versions: tuple[int, ...], kind: str
    ) -> _View:
        index = _Index()
        names = index.names
        if kind == "links":
            count = 0
            for root in roots:
                for rec in self.dirs.get(root, {}).values():
                    for path, target in rec.links.items():
                        index.add(path, target)
                    count += len(rec.links)
            return _View(versions, index, {}, count)
        pics_dirs: dict[str, list[str]] = {}
        count = 0
        for root in roots:
            records = self.dirs.get(root)
            if records is None:
                continue
            index.add(root)
            count += 1
            for directory, rec in records.items():
                for path in rec.entries:
                    names.setdefault(fs.basename(path), []).append(path)
                for path, target in rec.links.items():
                    index.link(path, target)
                count += len(rec.entries)
                if rec.lazy:
                    pics_dirs.setdefault(_pics_dnum(directory) or "", []).append(
                        directory
                    )
        return _View(versions, index, pics_dirs, count)

    @staticmethod
    def pics(
        view: _View, numeric: tuple[tuple[str, str], ...]
    ) -> list[tuple[str, bool]]:
        """Probe '<dnum>-<0..PICS_ZEROES zeroes><idx>.<ext>' inside every '<dnum>*' pics dir
        -> [(path, is_symlink)]. Nothing is listed or cached, and hits bypass name matching
        (the file is '123-0045.mp4', the needle '123-45')."""
        found: list[tuple[str, bool]] = []
        for dnum, idx in numeric:
            idx = str(int(idx))
            for directory in view.pics_dirs.get(dnum, ()):
                for zeros in range(C.PICS_ZEROES + 1):
                    for ext in C.PICS_EXTS:
                        path = fs.join(directory, f"{dnum}-{'0' * zeros}{idx}.{ext}")
                        if fs.lexists(path):
                            found.append((path, fs.islink(path)))
        return found

    # -- scanning ------------------------------------------------------------ #

    def _refresh(self, root: str, start: str | None = None) -> None:
        """Incremental os.stat walk (whole root, or the subtree at `start`): only directories
        whose mtime changed are re-read; vanished ones are dropped."""
        start = start or root
        records = self.dirs.setdefault(root, {})
        changed = replaced = False
        seen: dict[str, _Dir] = {}
        stack = [start]
        while stack:
            directory = stack.pop()
            try:
                mtime = os.stat(directory).st_mtime_ns
            except OSError:
                continue
            rec = records.get(directory)
            if rec is None or rec.mtime != mtime or rec.racy:
                fresh = _scan_dir(directory, root, mtime)
                if fresh is None:
                    if fs.isdir(directory):  # not just vanished: could not be listed
                        self.unreadable.add(directory)
                    continue
                self.unreadable.discard(directory)
                replaced = True
                changed = changed or rec is None or not _same_content(rec, fresh)
                rec = fresh
            seen[directory] = rec
            stack.extend(rec.subdirs)
        prefix = start + os.sep
        stale = [
            d for d in records if d not in seen and (d == start or d.startswith(prefix))
        ]
        if replaced or stale:
            records.update(seen)
            for directory in stale:
                del records[directory]
            self.unreadable.difference_update(stale)
        if changed or stale:
            self._bump(root)

    def _flush_visited(self, roots: Iterable[str]) -> None:
        """Rescan the subtrees of directories visited / targeted since the last seek."""
        dirty, self.visited = self.visited, set()
        bases = {root: (root, fs.realpath(root)) for root in roots if root in self.dirs}
        for directory in dirty:
            for root, spellings in bases.items():
                start = self._locate(root, spellings, directory)
                if start:
                    self._refresh(root, start)
                    break

    def _locate(
        self, root: str, spellings: tuple[str, str], directory: str
    ) -> str | None:
        """Nearest cached ancestor-or-self of `directory`, spelled like `root` does."""
        for base in spellings:
            if directory == base or directory.startswith(base + os.sep):
                directory = root + directory[len(base) :]
                break
        else:
            return None
        records = self.dirs[root]
        while directory not in records:
            parent = fs.dirname(directory)
            if parent == directory or len(parent) < len(root):
                return None
            directory = parent
        return directory

    def _prefill(self, roots: Iterable[str]) -> None:
        """Full (re)build; fd in parallel when available, scandir walk otherwise."""
        wanted = []
        for root in roots:
            if fs.isdir(root):
                wanted.append(root)
            elif self.dirs.pop(root, None) is not None:
                self._bump(root)
        if not wanted:
            return
        since = time.time_ns()
        listings = self._fd(wanted)
        for root in wanted:
            records = None
            self.unreadable = {d for d in self.unreadable if not d.startswith(root)}
            if listings is not None:
                records = self._from_listing(root, *listings[root], since)
            if records is None:
                self.dirs.pop(root, None)
                self._refresh(root)
            else:
                self.dirs[root] = records
                self._bump(root)

    @staticmethod
    def _fd(
        roots: list[str],
    ) -> dict[str, tuple[list[str], list[str], list[str]]] | None:
        base = ["fd", "--absolute-path", "--print0", "--hidden", "--no-ignore"]

        def run(job: tuple[str, str | None]) -> list[str]:
            root, kind = job
            args = base + (["--type", kind] if kind else []) + [".", root]
            result = subprocess.run(args, stdout=subprocess.PIPE, check=False)
            if (
                result.returncode != 0
            ):  # partial output would silently lose results: walk instead
                raise OSError(f"fd failed on {root}")
            # fd prints directories with a trailing "/"; normalise so dirname() works
            return [
                os.fsdecode(raw).rstrip("/")
                for raw in result.stdout.split(b"\0")
                if raw
            ]

        jobs = [(root, kind) for root in roots for kind in (None, "d", "l")]
        try:
            with ThreadPoolExecutor(min(len(jobs), 6)) as pool:
                out = list(pool.map(run, jobs))
        except OSError, subprocess.SubprocessError:
            return None
        return {
            root: (out[3 * i], out[3 * i + 1], out[3 * i + 2])
            for i, root in enumerate(roots)
        }

    def _from_listing(
        self,
        root: str,
        everything: list[str],
        dirs: list[str],
        links: list[str],
        since: int,
    ) -> dict[str, _Dir] | None:
        by_parent: dict[str, list[str]] = {}
        for path in everything:
            by_parent.setdefault(fs.dirname(path), []).append(path)
        if everything and root not in by_parent:
            return None  # fd printed paths not under `root` (resolved symlink?); walk instead
        dirset = set(dirs)
        targets = {path: _safe_readlink(path) or "" for path in links}
        records: dict[str, _Dir] = {}
        stack = [root]
        while stack:
            directory = stack.pop()
            try:
                mtime = os.stat(directory).st_mtime_ns
            except OSError:
                continue
            items = [
                (path, path in dirset, targets.get(path))
                for path in by_parent.get(directory, ())
            ]
            rec = _make_rec(directory, root, mtime, items, since)
            records[directory] = rec
            stack.extend(rec.subdirs)
            if not os.access(directory, os.R_OK | os.X_OK):
                self.unreadable.add(directory)
        return records

    def touch(self, paths: Iterable[str]) -> None:
        """Entries inside these paths' directories changed: re-read just those directories."""
        with self.lock:
            for directory in {fs.dirname(path) for path in paths}:
                for root, records in self.dirs.items():
                    if directory in records:
                        rec = _scan_dir(directory, root)
                        if rec is not None:
                            records[directory] = rec
                            self._bump(root)
                        break


def _shared_cache() -> _Cache:
    """One cache per process and per source revision: an unchanged module reload keeps
    the warm cache, an edited one starts clean (so old/new code never share state)."""
    try:
        with open(__file__, "rb") as handle:
            stamp = hashlib.sha1(handle.read()).hexdigest()
    except NameError, OSError:
        stamp = "unknown"
    holder = sys.modules.setdefault("_vdsym_shared", types.ModuleType("_vdsym_shared"))
    ## MOVED: the (owner, name) -> unpatched ranger method registry lives in rhooks.patch
    cache = getattr(holder, "cache", None)
    if getattr(cache, "stamp", None) != stamp:
        cache = holder.cache = _Cache(stamp)
    return cache


_cache = _shared_cache()


def _under_roots(path: str) -> bool:
    """Is `path` inside a VD root, by either its own or its resolved spelling?"""
    for form in {path, _norm(path)}:
        for root in vdsym.roots():
            for base in {root, fs.realpath(root)}:
                if form == base or form.startswith(base + os.sep):
                    return True
    return False


def _vd_root(path: str) -> str | None:
    """Resolved VD root containing `path`, if any."""
    path = fs.realpath(path)
    for root in vdsym.roots():
        root = fs.realpath(root)
        if path == root or path.startswith(root + os.sep):
            return root
    return None


class _Hit(NamedTuple):
    link: str  # symlink under the VD roots
    subject: str  # normalized subject path (or directory tree) its chain passes through
    rest: str  # path below `subject` when that is a directory tree, else ""
    direct: bool  # the link's first hop already is that place: only such links need re-pointing


def _match(link: str, subjects: set[str], trees: list[str]) -> _Hit | None:
    for index, hop in enumerate(_hops(link)):
        if hop in subjects:
            return _Hit(link, hop, "", index == 0)
        for tree in trees:
            if hop.startswith(tree + os.sep):
                return _Hit(link, tree, hop[len(tree) :], index == 0)
    return None


def find_hits(
    paths: Sequence[str], wait: float | None = None, dashboards: bool = False
) -> list[_Hit] | None:
    """Symlinks under the VD roots whose chain passes through any of `paths`.

    `paths` may be files, symlinks (then only links going *through* that symlink count, not
    its siblings) or directories (links into anything inside). Candidates come from the shared
    name index, chased through link-to-link chains by name, then verified hop by hop. The cache
    is mtime-validated first, so links created since the last scan are seen.
    `dashboards=True` also looks into DASHBOARD_ROOT (generated links; used when re-pointing).
    Returns None when the cache lock stays busy for `wait` seconds (warm-up still running).
    """
    subjects = {_norm(path) for path in paths}
    trees = (
        [s for s in subjects if fs.isdir(s) and not fs.islink(s)]
        if C.DELETE_SCANS_DIRS
        else []
    )
    pending = {fs.basename(path.rstrip("/")) for path in paths}
    done: set[str] = set()
    found: dict[str, None] = {}
    if not _cache.lock.acquire(timeout=-1 if wait is None else wait):
        return None
    try:
        roots = vdsym.link_roots() if dashboards else vdsym.roots()
        index = _cache.ensure(roots, "validate", "links").index
        while pending:
            name = pending.pop()
            done.add(name)
            for link in index.names.get(name, ()):
                if link in index.links and link not in found:
                    found[link] = None
                    base = fs.basename(link)
                    if base not in done:
                        pending.add(base)
        if trees:  # a link into a directory needn't share any name with it
            found.update(dict.fromkeys(sorted(index.links)))
    finally:
        _cache.lock.release()
    hits = (_match(link, subjects, trees) for link in found)
    return [hit for hit in hits if hit]


def find_backlinks(paths: Sequence[str]) -> list[str]:
    return [hit.link for hit in find_hits(paths) or []]


def _drop_moving(hits: list[_Hit], paths: Sequence[str]) -> list[_Hit]:
    """Links that travel with (or die with) the selection are not 'pointing back' at it."""
    moving = [_norm(path) for path in paths]
    return [
        hit
        for hit in hits
        if not any(
            _norm(hit.link) == m or _norm(hit.link).startswith(m + os.sep)
            for m in moving
        )
    ]


def _print_dismiss() -> tuple[str, str]:
    """Prompt text plus shell read loop for PRINT_DISMISS_KEYS."""
    spec = C.PRINT_DISMISS_KEYS
    if spec == "any":
        return " [any key]", "read -sk 1 2>/dev/null || read -rsn 1"
    if not isinstance(spec, str) or not spec:
        _LOG.warning("vdsym: invalid PRINT_DISMISS_KEYS=%r; using any", spec)
        return " [any key]", "read -sk 1 2>/dev/null || read -rsn 1"
    keys = set(spec)
    keys = {"" if key in "\n\r" else key for key in keys}
    labels = (["Enter"] if "" in keys else []) + (["space"] if " " in keys else [])
    labels += sorted((key for key in keys if key not in ("", " ")), key=str.casefold)
    choices = "|".join(shell_quote(key) for key in sorted(keys))
    return (
        " [" + "/".join(labels) + "]",
        "while :; do read -sk 1 key 2>/dev/null || read -rsn 1 key; "
        + f'case "$key" in {choices}) break;; esac; done',
    )


def make_dashboard(fm, matches: Sequence[str], dest: str) -> str:
    """Populate `dest` with one symlink per match (dropping stale symlinks) and cd there."""
    os.makedirs(dest, exist_ok=True)
    wanted: dict[str, str] = {}
    for source in matches:
        name = source.lstrip("/").replace("/", "⁄")
        if len(os.fsencode(name)) > 255:
            digest = hashlib.sha1(os.fsencode(source)).hexdigest()[:8]
            name = f"{name[-100:]}~{digest}"
        wanted[name] = source
    with os.scandir(dest) as it:
        stale = [e.path for e in it if e.is_symlink() and e.name not in wanted]
    for path in stale:
        os.unlink(path)
    for name, source in wanted.items():
        link = fs.join(dest, name)
        if not fs.lexists(link):
            os.symlink(source, link)
    for source in matches:
        _cache.visited.add(fs.dirname(source))
        _cache.visited.add(fs.dirname(fs.realpath(source)))
    fm.cd(dest)
    return dest


# --------------------------------------------------------------------------- #
# :vdsym
# --------------------------------------------------------------------------- #


class vdsym(Command):
    """:vdsym [-a] [-b] [-c] [-d] [-g] [-i] [-j] [-l] [-n] [-p] [-v] [-y]

    Search VD files and their symlink dashboards.
    """

    data_roots = ("/media/pro/vd", "/cache/vd", "/media/hpx/vd_ssdt5")
    view_root = "/d/irome/view"

    _parsed: tuple[set[str], list[str], str | None] | None = None
    _names_cache: list[str] | None = None
    _touched: set[str] | None = None
    _kpi: dict[str, float | int] = {}

    @classmethod
    def roots(cls, view_only: bool = False) -> tuple[str, ...]:
        return (cls.view_root,) if view_only else (cls.view_root,) + cls.data_roots

    @classmethod
    def link_roots(cls) -> tuple[str, ...]:
        """Where links to a file may live: the VD roots plus the generated dashboards."""
        return cls.roots() + (
            () if C.DASHBOARD_ROOT in cls.roots() else (C.DASHBOARD_ROOT,)
        )

    # -- argument parsing ----------------------------------------------------- #

    def _parse(self) -> tuple[set[str], list[str], str | None]:
        if self._parsed is not None:
            return self._parsed
        import shlex

        tokens = shlex.split(self.rest(1))
        filtered: list[str] = []
        eq_root: str | None = None
        d_root: str | None = None
        skip = False
        for index, token in enumerate(tokens):
            if skip:
                skip = False
                continue
            if token.startswith("--dashboard="):
                if eq_root is None:
                    eq_root = token.split("=", 1)[1]
                filtered.append(token)
                continue
            if (
                token in ("-d", "--dashboard")
                and index + 1 < len(tokens)
                and not tokens[index + 1].startswith("-")
            ):
                if d_root is None:
                    d_root = tokens[index + 1]
                skip = True
            filtered.append(token)
        flags: set[str] = set()
        names: list[str] = []
        separator = False
        for token in filtered:
            if not separator and token == "--":
                separator = True
            elif not separator and token.startswith("--"):
                option, equals, value = token[2:].partition("=")
                try:
                    if option in _GROUPS and equals:
                        for item in value.split(","):
                            flags.add(_GROUPS[option][item])
                    else:
                        flags.add(_LONG_FLAGS[option])
                except KeyError as error:
                    raise ValueError(f"unknown option {token!r}") from error
            elif not separator and token.startswith("-"):
                flags.update(token[1:])
            else:
                names.append(token)
                separator = True
        root = eq_root if eq_root is not None else d_root
        self._parsed = (flags, names, root)
        return self._parsed

    def _args(self) -> tuple[set[str], list[str]]:
        flags, names, _ = self._parse()
        return flags, names

    def _dashboard_root(self) -> str | None:
        return self._parse()[2]

    def _name(self) -> str:
        names = self._names()
        return names[0] if names else ""

    def _names(self) -> list[str]:
        if self._names_cache is None:
            self._names_cache = self._compute_names()
        return self._names_cache

    def _compute_names(self) -> list[str]:
        flags, arguments = self._args()
        if arguments:
            return [fs.basename(argument) for argument in arguments]
        if "s" in flags:
            return [entry.basename for entry in self.fm.thistab.get_selection()]
        if "c" in flags:
            try:
                clipboard = subprocess.run(
                    ["xco"], stdout=subprocess.PIPE, text=True, check=False
                ).stdout
            except OSError:
                self.fm.notify("xco not available", bad=True)
                return []
            return [fs.basename(line) for line in clipboard.splitlines()]
        if "b" in flags:
            return [self.fm.thisfile.basename] if self.fm.thisfile else []
        if "y" in flags:
            return [entry.basename for entry in self.fm.copy_buffer]
        return []

    @staticmethod
    def _normalize(name: str, flags: set[str]) -> str:
        if "n" in flags:
            exts = "|".join(("html",) + C.PICS_EXTS)
            if match := _NUMERIC.fullmatch(re.sub(rf"\.(?:{exts})$", "", name)):
                return f"{match[1]}-{match[2]}"
            return re.sub(r"\.html$", "", name)
        return name

    def _paths(self, flags: set[str]) -> list[str]:
        if "s" in flags:
            return [fs.abspath(entry.path) for entry in self.fm.thistab.get_selection()]
        if "y" in flags:
            return [fs.abspath(entry.path) for entry in self.fm.copy_buffer]
        return []

    # -- replace ---------------------------------------------------------------- #

    def _replace_links(self, flags: set[str]) -> None:
        source = fs.realpath(self.fm.thisfile.path)
        targets = self._paths(flags)
        if not fs.isfile(source) or len(targets) != 1 or not fs.isfile(targets[0]):
            self.fm.notify(
                "Need one existing cursor file and one yanked file.", bad=True
            )
            return
        self._touched = set()
        self._ask_replace(find_backlinks([source]), source, targets[0], False)

    def _finish_replace(self) -> None:
        if self._touched:
            _cache.touch(self._touched)
            self._touched = set()

    def _show_links(self, links: list[str]) -> None:
        output = "\n".join(
            f"{link} -> {os.readlink(link)}" for link in links if fs.islink(link)
        )
        self.fm.execute_command("printf '%s\\n' " + shell_quote(output), flags="-w")

    def _ask_replace(
        self, links: list[str], source: str, target: str, automatic: bool
    ) -> None:
        if automatic:
            for link in links:
                self._replace_one(link, source, target)
            return self._finish_replace()
        if not links:
            return self._finish_replace()
        link, *remaining = links
        current = _safe_readlink(link) or "?"
        self.fm.ui.console.ask(
            f"Replace ({len(links)} remaining): {link} -> {current}? (Quit/Yes/No/All/List)",
            lambda answer: self._replace_one_answer(
                answer, link, remaining, source, target
            ),
            ("q", "Q", "y", "Y", "n", "N", "a", "A", "l", "L"),
        )

    def _replace_one_answer(
        self, answer: str, link: str, remaining: list[str], source: str, target: str
    ) -> None:
        answer = answer.lower()
        if answer == "l":
            self._show_links([link] + remaining)
            self._ask_replace([link] + remaining, source, target, False)
        elif answer in ("y", "a"):
            self._replace_one(link, source, target)
            self._ask_replace(remaining, source, target, answer == "a")
        elif answer == "n":
            self._ask_replace(remaining, source, target, False)
        else:
            self._finish_replace()

    def _replace_one(self, link: str, source: str, target: str) -> None:
        if not fs.islink(link) or fs.realpath(link) != source:
            return
        error = replace_link(link, fs.relpath(target, fs.dirname(link)), target)
        if error:
            self.fm.notify(error, bad=True)
        elif self._touched is not None:
            self._touched.add(fs.join(fs.dirname(link), fs.basename(target)))

    # -- search ------------------------------------------------------------------ #

    @staticmethod
    def _mode(flags: set[str]) -> str:
        if "Q" in flags:
            return "rescan"
        if "N" in flags:
            return "none"
        if "q" in flags:
            return "validate"
        return C.REFRESH if C.REFRESH in ("validate", "visited", "none") else "validate"

    def _source_paths(self, flags: set[str]) -> set[str]:
        """Paths the needles were taken from (cursor / selection / yank), if not explicit."""
        _, arguments = self._args()
        if arguments or "c" in flags:
            return set()
        if "s" in flags:
            entries = self.fm.thistab.get_selection()
        elif "b" in flags:
            entries = [self.fm.thisfile] if self.fm.thisfile else []
        elif "y" in flags:
            entries = self.fm.copy_buffer
        else:
            entries = []
        return {_norm(entry.path) for entry in entries}

    def _without_sources(self, matches: list[str], flags: set[str]) -> list[str]:
        """A symlink under the cursor must not 'find' itself (then jump does nothing, silently)."""
        sources = self._source_paths(flags)
        return [m for m in matches if _norm(m) not in sources] if sources else matches

    def _matches(self) -> list[str]:
        started = time.perf_counter()
        flags, _ = self._args()
        mode = self._mode(flags)
        roots = self.roots("v" in flags)
        with _cache.lock:
            view = _cache.ensure(roots, mode)
            expanded = time.perf_counter()
            needles = [self._normalize(name, flags) for name in self._names()]
            numeric = tuple(
                sorted({(m[1], m[2]) for n in needles if (m := _NUMERIC.fullmatch(n))})
            )
            matches = self._lookup([view.index], needles, flags)
            if numeric:
                known = set(matches)
                matches += [
                    path
                    for path, is_link in _cache.pics(view, numeric)
                    if (is_link or "l" not in flags) and path not in known
                ]
        if mode in (
            "none",
            "visited",
        ):  # the cache may be stale: drop what is gone, whatever the size
            matches = [path for path in matches if not _gone(path)]
        self._kpi = {
            "scan": expanded - started,
            "filter": time.perf_counter() - expanded,
            "paths": view.count,
            "matches": len(matches),
        }
        self._warn_unreadable(roots)
        return matches

    def _warn_unreadable(self, roots: Sequence[str]) -> None:
        bad = frozenset(
            d
            for d in _cache.unreadable
            if any(d == r or d.startswith(r + os.sep) for r in roots)
        )
        if bad and bad != _cache.reported_unreadable:
            _LOG.warning("vdsym: unreadable directories: %s", sorted(bad))
            self.fm.notify(
                f"{len(bad)} unreadable dir(s): results may be incomplete (:display_log)",
                bad=True,
            )
        _cache.reported_unreadable = bad

    @staticmethod
    def _lookup(
        sources: list[_Index], needles: list[str], flags: set[str]
    ) -> list[str]:
        icase, glob, links_only = "i" in flags, "g" in flags, "l" in flags
        matches: list[str] = []
        seen: set[str] = set()
        for needle in needles:
            if icase:
                needle = needle.casefold()
            for index in sources:
                for path in index.find(needle, glob, icase):
                    if links_only and path not in index.links:
                        continue
                    if path not in seen:
                        seen.add(path)
                        matches.append(path)
        return matches

    def _report_kpi(self, started: float, operation: float) -> None:
        kpi = self._kpi
        _LOG.info(
            "vdsym kpi: total=%.3fs scan=%.3fs filter=%.3fs op=%.3fs paths=%d matches=%d",
            time.perf_counter() - started,
            kpi.get("scan", 0.0),
            kpi.get("filter", 0.0),
            time.perf_counter() - operation,
            kpi.get("paths", 0),
            kpi.get("matches", 0),
        )

    # -- actions ------------------------------------------------------------------- #

    def _dashboard(self, matches: list[str]) -> str:
        root = self._dashboard_root()
        flags, _ = self._args()
        # with a selection the subdir is named after the file under the cursor, not the 1st selected
        cursor = self.fm.thisfile
        name = cursor.basename if "s" in flags and cursor else self._name()
        dest = (
            fs.join(root, name)
            if root is not None
            else fs.join(C.DASHBOARD_ROOT, self.fm.thisfile.relative_path)
        )
        return make_dashboard(self.fm, matches, dest)

    def _yank(self, matches: list[str]) -> None:
        subprocess.run(["xci"], input="\n".join(matches), text=True, check=False)

    def _jump(self, matches: list[str], position: int | None = None) -> None:
        if not matches:
            return
        current = self.fm.thisfile.path
        rotate = "r" in self._args()[0]
        current_norm = _norm(current)
        members = {_norm(path) for path in [current, *matches]}
        state = _ROTATIONS.get(id(self.fm))
        if state is None or state["members"] != members or current_norm not in state["index"]:
            locations = [current]
            seen = {current_norm}
            for match in matches:
                normalized = _norm(match)
                if normalized not in seen:
                    seen.add(normalized)
                    locations.append(match)
            state = {
                "members": members,
                "locations": locations,
                "index": {_norm(path): index for index, path in enumerate(locations)},
            }
            _ROTATIONS[id(self.fm)] = state
        locations = state["locations"]
        alternatives = len(locations) - 1
        if position is not None:
            target_index = min(max(1, position), alternatives)
            target = locations[target_index]
        elif rotate:
            target_index = (state["index"][current_norm] + 1) % len(locations)
            target = locations[target_index]
        else:
            target = self._jump_fallback(matches, current, fs.realpath(current))
            target_index = state["index"].get(_norm(target), 0)
        self.fm.select_file(target)
        if "o" in self._args()[0]:
            self.fm.move(right=1)
        if alternatives > 1:
            self.fm.notify(f"MULTI ({target_index}/{alternatives})")

    def _jump_fallback(
        self, matches: list[str], current: str, current_real: str
    ) -> str:
        dashboard_match = next(
            (
                fs.join(self.fm.thisdir.path, entry.basename)
                for entry in self.fm.thisdir.files or ()
                if entry.is_link and fs.realpath(entry.path) == current_real
            ),
            None,
        )
        return dashboard_match or matches[0]

    def _print(self, matches: list[str], flags: set[str]) -> None:
        needles = [self._normalize(name, flags) for name in self._names()]
        pattern = re.compile(
            "|".join(re.escape(n) for n in needles if n) or "(?!)",
            re.IGNORECASE if "i" in flags else 0,
        )

        def esc(value: str) -> str:  # printf %b would otherwise eat backslashes
            return value.replace("\\", "\\\\")

        yellow = "\\033[33;1m"

        def color(value: str) -> str:
            return f"{yellow}{esc(value)}\\033[m"

        def highlight_needle(value: str) -> str:
            out, last = [], 0
            for match in pattern.finditer(value):
                out.append(esc(value[last : match.start()]))
                out.append(color(match[0]))
                last = match.end()
            out.append(esc(value[last:]))
            return "".join(out)

        def highlight_rest(value: str) -> str:
            base = fs.basename(value)
            found = tuple(pattern.finditer(base))
            if not found:
                return esc(value)
            prefix = value[: len(value) - len(base)]
            out, last = [esc(prefix)], 0
            for match in found:
                out.append(color(base[last : match.start()]))
                out.append(esc(match[0]))
                last = match.end()
            out.append(color(base[last:]))
            return "".join(out)

        highlight = highlight_rest if C.PRINT_HIGHLIGHT == "rest" else highlight_needle

        if matches:
            lines = []
            for match in matches:
                line = highlight(match)
                if fs.islink(match):
                    line += f"  ->  {highlight(os.readlink(match))}"
                lines.append(line)
            output = "\\n".join(lines)
        else:
            output = "\\033[31;40;1mnotfound\\033[m "
        dismiss, read = _print_dismiss()
        self.fm.execute_command(
            "printf '%b\\n' "
            + shell_quote(output)
            + "; printf '%s' "
            + shell_quote(dismiss)
            + "; "
            + read
        )

    def execute(self) -> None:
        """Run the PREFLIGHT hooks (vddangling: tell about newly dangling links; each calls
        proceed() to go on, maybe after a prompt, or not at all to abort), then the command."""
        try:
            flags, _ = self._args()
        except ValueError as error:
            self.fm.notify(f"vdsym: {error}", bad=True)
            return
        pending = list(HOOKS["preflight"].values())

        def step() -> None:
            if not pending:
                return self._execute()
            fn = pending.pop(0)
            called: list[bool] = []

            def proceed() -> None:
                if not called:  # a prompt answered twice must not run the command twice
                    called.append(True)
                    step()

            fn(self, flags, proceed)

        step()

    ## ALT: dangling check hard-wired into :vdsym (before the PREFLIGHT hooks existed)
    ##      benefit: one file, no hook indirection; cost: vdsym core had to know the monitor
    #     def execute(self) -> None:
    #         """Compare dangling links with the previous check first (when the cache is refreshed
    #         anyway), tell about new ones, then run the command."""
    #         try:
    #             flags, _ = self._args()
    #         except ValueError as error:
    #             self.fm.notify(f"vdsym: {error}", bad=True)
    #             return
    #         _arm()
    #         new = None
    #         if "N" not in flags and self._mode(flags) in ("validate", "rescan"):
    #             new = check_dangling(self.fm, notify=False)
    #         if not new:
    #             return self._execute()
    #         # Enter = continue, Esc = abort the command
    #         self.fm.ui.console.ask(
    #             f"{len(new)} symlink(s) newly dangling: {_brief(map(fs.basename, new))}"
    #             " (:display_log) -- Enter=continue / Esc=abort / l=list / U=re-point",
    #             lambda ans: self._after_dangling(ans, new),
    #             ("c", "q", "l", "U"),
    #         )
    #
    #     def _after_dangling(self, answer: str, new: list[str]) -> None:
    #         if answer == "q":
    #             return
    #         if answer == "l":
    #             _list_dangling(self.fm, new)
    #         elif answer == "U":
    #             _repoint_unique(self.fm, new)
    #         self._execute()
    #

    def _execute(self) -> None:
        started = time.perf_counter()
        try:
            flags, _ = self._args()
        except ValueError as error:
            self.fm.notify(f"vdsym: {error}", bad=True)
            return
        if flags & {"q", "Q"} and not flags & set("adjopxR"):
            self._matches()
            self._report_kpi(started, time.perf_counter())
            return
        if "R" in flags:
            self._replace_links(flags)
            self._report_kpi(started, time.perf_counter())
            return
        names = self._names()
        if len(names) > 1 and "m" not in flags:
            self.fm.notify("Source has multiple needles; use --multiple.", bad=True)
            self._report_kpi(started, time.perf_counter())
            return
        if not names:
            self.fm.notify(
                "Use --basename, --clipboard, or an explicit name.",
                duration=1,
                bad=True,
            )
            self._report_kpi(started, time.perf_counter())
            return
        matches = self._without_sources(self._matches(), flags)
        operation = time.perf_counter()
        if not matches and "a" not in flags and "p" not in flags:
            self.fm.notify(f"No matches for '{self._name()}'.", duration=1, bad=True)
            self._report_kpi(started, operation)
            return
        if "a" in flags:
            if not matches:
                self.fm.notify(
                    f"No matches for '{self._name()}'.", duration=1, bad=True
                )
            elif len(matches) == 1:
                self._jump(matches, self.quantifier)
            else:
                self._dashboard(matches)
        elif "x" in flags:
            self._yank(matches)
        elif "d" in flags:
            self._dashboard(matches)
        elif "p" in flags:
            if "r" in flags and matches:
                current = self.fm.thisfile.path
                if current in matches:
                    matches = [matches[(matches.index(current) + 1) % len(matches)]]
                else:
                    matches = [matches[0]]
            self._print(matches, flags)
        elif "j" in flags:
            self._jump(matches, self.quantifier)
        else:
            self.fm.select_file(matches[0])
            if "o" in flags:
                self.fm.move(right=1)
        self._report_kpi(started, operation)


# --------------------------------------------------------------------------- #
# cd signal: lazy warm-up + "visited" bookkeeping (a signal via rhooks.on_cd, NOT a
# Tab.enter_dir wrapper: history_navi inspects the caller frame of enter_dir and must stay the
# outermost wrapper)
# --------------------------------------------------------------------------- #


def _warm() -> None:
    try:
        roots = vdsym.roots()
        _cache.ensure(roots)
        _cache.ensure(roots[:1])  # view-only index used by --modifiers=view
        for fn in list(
            HOOKS["warm"].values()
        ):  # was: dangling baseline (see vddangling)
            fn()
    except Exception:
        _LOG.exception("vdsym warm-up failed")


def _on_cd(path: str) -> None:
    if not _under_roots(path):
        return
    _cache.visited.add(path)
    _cache.visited.add(fs.realpath(path))
    for fn in list(HOOKS["cd"].values()):  # was: _arm() of the dangling timer
        fn(path)
    if C.WARM_ON_CD and not _cache.warmed:
        _cache.warmed = True
        threading.Thread(target=_warm, name="vdsym-warm", daemon=True).start()


rhooks.on_cd("vdsym", _on_cd)

## ALT: own cd-signal binding + hook_init wrapper (now rhooks.on_cd, shared by all plugins)
##      benefit: self-contained; cost: every plugin binding "cd" repeats the same dance
# def _on_cd_signal(signal) -> None:
#     new = getattr(signal, "new", None)
#     if new is not None:
#         try:
#             _on_cd(new.path)
#         except Exception:
#             _LOG.exception("vdsym cd handler failed")
# def _bind_cd(fm) -> None:
#     if fm is None or getattr(fm, "_vdsym_cd", None) == _cache.stamp:
#         return
#     fm._vdsym_cd = _cache.stamp
#     _cache.fm = fm
#     fm.signal_bind("cd", _on_cd_signal)
