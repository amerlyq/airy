"""VD symlink search and replacement command, plus a link-aware :delete.

Layout:
- _Cache      process-wide directory cache + per-roots search views (shared by
              :vdsym, :delete and the replace flow; survives module re-exec)
- vdsym       the command
- find_backlinks / make_dashboard
              reusable helpers (what :delete calls)
- delete      :delete with clip + symlink guards (only for paths inside the VD roots)
- moves       fm.cut / fm.paste / :rename ask about clips + symlinks first and can re-point (U)
              or replace (R) the symlinks once the files have really moved; every prompt is
              preceded by a list of the links, also appended to RECOVERY_LOG
- dangling   links that start to dangle behind ranger's back (bulkrename, shell mv/rm) are
              reported by the next refreshing :vdsym and, failing that, by a ranger timer
- cd signal   lazy cache warm-up on the first cd() into a VD root, "visited" dir bookkeeping
"""

from __future__ import annotations

import errno
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
from typing import Callable, NamedTuple

from ranger.api.commands import Command
from ranger.config.commands import delete as _default_delete
from ranger.config.commands import rename as _default_rename
from ranger.ext.safe_path import get_safe_path
from ranger.ext.shell_escape import shell_quote

DASHBOARD_ROOT = "/t/bnm"
# Cache freshness before a :vdsym search.
#
# "validate" stat-walks every cached directory.
# It rescans only directories whose mtime changed.
# This catches changes made outside ranger.
# It is reliable when directory mtimes are reliable.
# It costs one stat per cached directory.
# It is the default.
#
# "visited" remembers each VD directory reached by ranger's cd signal.
# It remembers both the displayed spelling and realpath spelling.
# The next visited-mode search rescans each remembered directory subtree.
# Dashboard creation also remembers source directories plus symlink target directories.
# This cheaply catches work done during this ranger session.
# It can miss external changes in unvisited directories.
# It can miss a symlinked directory when ranger keeps an outside symlink-leaf spelling.
#
# "none" trusts the index except that gone matched paths are filtered out.
# "rescan" rebuilds every root from scratch.
#
# --modifiers=norefresh forces "none".
# --action=refresh forces "validate".
# --action=rescan forces "rescan".
REFRESH = "validate"
WARM_ON_CD = True  # start the background cache build on the first cd() under a VD root
DELETE_SCANS_DIRS = True  # :delete also looks for links into directories being deleted

# Pictures live in "<dnum>" or "<dnum>-*" dirs directly under a parent named like one of these
# (the first "*" is the date prefix). Those dirs are never listed; for a needle "<dnum>-<idx>"
# the files "<dnum>-<idx>.<ext>" with 0..PICS_ZEROES zeroes before <idx> are probed instead.
PICS_PARENTS = ("*-*-pics", "*-*-pics-*")
PICS_EXTS = ("mp4", "webp", "gif")
PICS_ZEROES = 3

LOCK_WAIT = (
    3.0  # s a guard waits for the cache lock (warm-up running) before asking blind
)
PRINT_BEFORE_PROMPT = (
    True  # page the symlink list before a move prompt (recovery on cancel/crash)
)
# "any" accepts the next key.
# Any other string accepts only its characters.
# Use "\n yqc" for Enter, space, y, q or c.
PRINT_DISMISS_KEYS = "any"
# Print-match emphasis is bold yellow.
# "rest" emphasizes matching basenames except for the search term.
# "needle" emphasizes the search term instead.
PRINT_HIGHLIGHT = "rest"
RECOVERY_LOG = os.path.join(
    os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"),
    "vdsym",
    "moves.log",
)
RACY_NS = 2_000_000_000  # dirs modified < 2s before their scan are re-read next time

# Dangling symlinks: bulkrename, shell mv / rm and other tools can't be hooked, so they are
# caught afterwards. Every :vdsym that refreshes compares the links that dangle now with the
# previous check and, before doing its job, tells you about new ones. If you then stop using
# vdsym, a ranger timer repeats the comparison once after DANGLING_QUIET s without VD activity.
DANGLING_MONITOR = True
DANGLING_QUIET = 30.0

# Clip naming: "<stem>_00m33s6", "<stem>_v32", "<stem>_06m44s7_prev29267", any extension.
_TOKEN = r"(?:\d+m\d+s\d+|v\d+|prev\d+)"
_CLIP_SUFFIX = _TOKEN + "(?:_" + _TOKEN + ")*"

_NUMERIC = re.compile(r"(\d+)-0*(\d+)")
_LOG = logging.getLogger("ranger.vdsym")

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
        for pattern in PICS_PARENTS
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


def _safe_readlink(path: str) -> str | None:
    try:
        return os.readlink(path)
    except OSError:
        return None


def _make_rec(
    directory: str,
    root: str,
    mtime: int,
    items: Iterable[tuple[str, bool, str | None]],
    since: int | None = None,
) -> _Dir:
    """`since`: when the listing the items come from was started; a directory modified after
    that may have changed between fd's separate runs, so it is re-read at the next validation."""
    racy = time.time_ns() - mtime < RACY_NS or (since is not None and mtime >= since)
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


# --------------------------------------------------------------------------- #
# shared cache
# --------------------------------------------------------------------------- #


class _Monitor:
    """Dangling-symlink bookkeeping (see check_dangling)."""

    def __init__(self) -> None:
        self.known: set[str] | None = (
            None  # dangling at the previous check; None = no baseline yet
        )
        self.deadline: float | None = (
            None  # monotonic time of the pending one-shot check
        )
        self.total = 0


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
        self.fm = None
        self.monitor = _Monitor()

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
                for zeros in range(PICS_ZEROES + 1):
                    for ext in PICS_EXTS:
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
        except (OSError, subprocess.SubprocessError):
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
    except (NameError, OSError):
        stamp = "unknown"
    holder = sys.modules.setdefault("_vdsym_shared", types.ModuleType("_vdsym_shared"))
    if not hasattr(holder, "orig"):
        holder.orig = {}  # (owner, name) -> the unpatched ranger method
    cache = getattr(holder, "cache", None)
    if getattr(cache, "stamp", None) != stamp:
        cache = holder.cache = _Cache(stamp)
    return cache


_cache = _shared_cache()


# --------------------------------------------------------------------------- #
# reusable helpers
# --------------------------------------------------------------------------- #


def _gone(path: str) -> bool:
    """Definitely not there (ENOENT / ENOTDIR). Unreadable or erroring paths count as present:
    a result is only dropped when we are sure it no longer exists."""
    try:
        os.lstat(path)
    except (FileNotFoundError, NotADirectoryError):
        return True
    except OSError:
        return False
    return False


def _dangling(link: str) -> bool:
    """The link leads nowhere (or loops). Errors that say nothing about that (EACCES, EIO,
    a hung mount) are not 'dangling'."""
    try:
        os.stat(link)
    except (FileNotFoundError, NotADirectoryError):
        return True
    except OSError as error:
        return error.errno == errno.ELOOP
    return False


def _acknowledge(links: Iterable[str]) -> None:
    """The user knowingly leaves these links dangling ("y" at a prompt): not news later."""
    known = _cache.monitor.known
    if known is not None:
        known.update(links)


def _norm(path: str) -> str:
    """Absolute path with parent directories resolved but the leaf kept (so a symlink stays itself)."""
    head, tail = fs.split(fs.abspath(path))
    return fs.join(fs.realpath(head), tail)


def _under_roots(path: str) -> bool:
    """Is `path` inside a VD root, by either its own or its resolved spelling?"""
    for form in {path, _norm(path)}:
        for root in vdsym.roots():
            for base in {root, fs.realpath(root)}:
                if form == base or form.startswith(base + os.sep):
                    return True
    return False


def _hops(link: str, limit: int = 40) -> Iterable[str]:
    """Successive targets of a symlink chain (each hop: parents resolved, leaf kept)."""
    current = link
    for _ in range(limit):
        if not fs.islink(current):
            return
        target = _safe_readlink(current)
        if target is None:
            return
        current = _norm(fs.join(fs.dirname(current), target))
        yield current


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
        if DELETE_SCANS_DIRS
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


def _brief(items: Iterable[str], limit: int = 3) -> str:
    items = list(items)
    more = f" +{len(items) - limit}" if len(items) > limit else ""
    return " | ".join(items[:limit]) + more


def _print_dismiss() -> tuple[str, str]:
    """Prompt text plus shell read loop for PRINT_DISMISS_KEYS."""
    spec = PRINT_DISMISS_KEYS
    if spec == "any":
        return " [any key]", "read -sk 1 2>/dev/null || read -rsn 1"
    if not isinstance(spec, str) or not spec:
        _LOG.warning("vdsym: invalid PRINT_DISMISS_KEYS=%r; using any", spec)
        return " [any key]", "read -sk 1 2>/dev/null || read -rsn 1"
    keys = set(spec)
    keys = {"" if key in "\n\r" else key for key in keys}
    labels = (["Enter"] if "" in keys else []) + (["space"] if " " in keys else [])
    labels += sorted(
        (key for key in keys if key not in ("", " ")), key=str.casefold
    )
    choices = "|".join(shell_quote(key) for key in sorted(keys))
    return (
        " [" + "/".join(labels) + "]",
        "while :; do read -sk 1 key 2>/dev/null || read -rsn 1 key; "
        + f"case \"$key\" in {choices}) break;; esac; done",
    )


def find_clips(paths: Sequence[str]) -> list[str]:
    """Siblings named '<stem>_<clip tokens>[.ext]' that are not themselves in `paths`."""
    stems: dict[str, list[str]] = {}
    for path in paths:
        stems.setdefault(fs.dirname(path), []).append(fs.splitext(fs.basename(path))[0])
    selected = set(paths)
    found: list[str] = []
    for directory, group in stems.items():
        pattern = re.compile(
            f"(?:{'|'.join(map(re.escape, group))})_{_CLIP_SUFFIX}(?:\\..*)?", re.S
        )
        try:
            with os.scandir(directory) as it:
                found.extend(
                    e.path
                    for e in it
                    if e.path not in selected and pattern.fullmatch(e.name)
                )
        except OSError:
            continue
    return sorted(found)


# --------------------------------------------------------------------------- #
# writing symlinks
# --------------------------------------------------------------------------- #


def _swap_link(link: str, text: str, dest: str | None = None) -> None:
    """Atomically make `dest` (default: `link`) a symlink to `text`."""
    dest = dest or link
    temporary = fs.join(
        fs.dirname(link), f".{fs.basename(dest)[:200]}.vdsym-{os.getpid()}"
    )
    try:
        os.symlink(text, temporary)
        os.replace(temporary, dest)
    except OSError:
        if fs.lexists(temporary):
            os.unlink(temporary)
        raise


def replace_link(link: str, text: str, target: str) -> str | None:
    """Swap `link` for a link in the same dir named exactly like `target`, holding `text`.
    Returns an error message (collision / OS error) or None."""
    new_link = fs.join(fs.dirname(link), fs.basename(target))
    if new_link != link and fs.lexists(new_link):
        if not (fs.islink(new_link) and fs.realpath(new_link) == fs.realpath(target)):
            return f"Collision: {new_link}"
        try:
            os.unlink(link)  # an equivalent link is already there
        except OSError as error:
            return str(error)
        return None
    try:
        _swap_link(link, text, new_link)
        if new_link != link:
            os.unlink(link)
    except OSError as error:
        return str(error)
    return None


def _link_text(link: str, old_raw: str, new_raw: str, rest: str) -> str:
    """Target text for `link` once `old_raw` became `new_raw`: same style (absolute / relative),
    and the same spelling of the path when the old text was absolute."""
    raw = _safe_readlink(link) or ""
    new_abs = _norm(new_raw) + rest
    if fs.isabs(raw):
        text, old = fs.normpath(raw), fs.normpath(old_raw)
        if text == old or text.startswith(old + os.sep):
            return fs.normpath(new_raw) + text[len(old) :]
        return new_abs
    return fs.relpath(new_abs, fs.realpath(fs.dirname(link)))


def _recovery(op: str, lines: Iterable[str]) -> None:
    """Append what is about to happen, so a crash / cancel / error can be undone by hand."""
    try:
        os.makedirs(fs.dirname(RECOVERY_LOG), exist_ok=True)
        if fs.exists(RECOVERY_LOG) and fs.getsize(RECOVERY_LOG) > 2_000_000:
            os.replace(RECOVERY_LOG, RECOVERY_LOG + ".1")
        with open(
            RECOVERY_LOG, "a", encoding="utf-8", errors="surrogateescape"
        ) as handle:
            handle.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S')} {op}\n")
            for line in lines:
                handle.write(f"  {line}\n")
    except OSError:
        _LOG.warning("cannot write %s", RECOVERY_LOG)


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
# guarded moves: shared by fm.cut / fm.paste / :rename
# --------------------------------------------------------------------------- #


class _MoveJob:
    """Re-point (U) or replace (R) symlinks once the files they led to have really moved.

    Hits are computed *before* the move (a moved directory can no longer be walked), applied
    after it, and only for files that are gone from `old` and found at their new place, so a
    cancelled or failed move leaves everything as it was. The new place is the predicted
    path, verified (and if needed searched in the destination dir) by inode.
    Links in DASHBOARD_ROOT are always re-pointed in place.
    """

    def __init__(
        self, fm, moves: dict[str, str], policy: dict[str, str], hits: list[_Hit]
    ) -> None:
        self.fm, self.moves, self.policy, self.hits = fm, moves, policy, hits
        self.by_subject = {_norm(old): old for old in moves}
        self.ids: dict[str, tuple[int, int]] = {}
        for old in moves:
            try:
                st = os.lstat(old)
                self.ids[old] = (st.st_dev, st.st_ino)
            except OSError:
                pass
        self.done = False

    def _locate(self, old: str, predicted: str) -> str | None:
        if fs.lexists(old):
            return None  # still there: not moved (cancelled, failed, copy not finished)
        ident = self.ids.get(old)
        if fs.lexists(predicted):
            if ident is None:
                return predicted
            st = os.lstat(predicted)
            if (st.st_dev, st.st_ino) == ident or st.st_dev != ident[0]:
                return predicted  # same inode, or copied across filesystems (inode can't tell)
        if (
            ident
        ):  # predicted name was wrong (name clash in the batch, race): find by inode
            try:
                with os.scandir(fs.dirname(predicted)) as it:
                    for entry in it:
                        st = entry.stat(follow_symlinks=False)
                        if (st.st_dev, st.st_ino) == ident:
                            return entry.path
            except OSError:
                pass
        return None

    @staticmethod
    def _is_dashboard(link: str) -> bool:
        return fs.abspath(link).startswith(fs.abspath(DASHBOARD_ROOT) + os.sep)

    def finish(self) -> None:
        if self.done:
            return
        self.done = True
        located = {
            old: self._locate(old, predicted) for old, predicted in self.moves.items()
        }
        problems: list[str] = []
        work: list[tuple[_Hit, str, str]] = []
        for hit in self.hits:
            old = self.by_subject.get(hit.subject)
            if old is None:
                continue
            new = located.get(old)
            if new is None:
                note = f"not moved: {old} (links to it left alone)"
                if note not in problems:
                    problems.append(note)
                continue
            work.append((hit, old, new))
        # a link that already has the final name goes first, the others then find it in place
        # and are simply removed (otherwise they would collide with it)
        work.sort(
            key=lambda w: fs.basename(w[0].link) != fs.basename(_norm(w[2]) + w[0].rest)
        )
        touched: set[str] = set()
        updated = replaced = kept = 0
        for hit, old, new in work:
            mode = "UA" if self._is_dashboard(hit.link) else self.policy.get(old)
            try:
                text = _link_text(hit.link, old, new, hit.rest)
                if mode == "UA" or (mode == "U" and hit.direct):
                    _swap_link(hit.link, text)
                    updated += 1
                elif mode == "R":
                    error = replace_link(hit.link, text, _norm(new) + hit.rest)
                    if error and error.startswith("Collision"):
                        # a foreign file owns the wanted name: never overwrite it, but don't
                        # leave the old link dangling either - re-point it under its old name
                        _swap_link(hit.link, text)
                        kept += 1
                        problems.append(f"{error} - kept {hit.link} (re-pointed)")
                    elif error:
                        problems.append(f"{hit.link}: {error}")
                        continue
                    else:
                        replaced += 1
                else:
                    continue
            except OSError as error:
                problems.append(f"{hit.link}: {error}")
                continue
            touched.add(hit.link)
            touched.add(fs.join(fs.dirname(hit.link), fs.basename(new)))
        if touched:
            _cache.touch(touched)
        _arm()
        for old, new in located.items():
            _cache.visited.add(fs.dirname(old))
            if new:
                _cache.visited.add(fs.dirname(new))
        _recovery(
            f"done updated={updated} replaced={replaced} kept={kept} problems={len(problems)}",
            problems,
        )
        if updated or replaced or kept or problems:
            self.fm.notify(
                f"symlinks: {updated} updated, {replaced} replaced"
                + (f", {kept} re-pointed in place (name taken)" if kept else "")
                + (
                    f", {len(problems)} problem(s) (see {RECOVERY_LOG})"
                    if problems
                    else ""
                ),
                bad=bool(problems),
            )


def _print_links(fm, op: str, hits: list[_Hit]) -> None:
    if not PRINT_BEFORE_PROMPT or not hits:
        return
    lines = [f"{op}: {len(hits)} symlink(s) lead here"]
    lines += [f"{hit.link} -> {_safe_readlink(hit.link) or '?'}" for hit in hits]
    fm.execute_command("printf '%s\\n' " + shell_quote("\n".join(lines)), flags="-w")


def _guard_move(
    fm,
    paths: Sequence[str],
    op: str,
    done: Callable[[str], None],
    cancel: Callable[[], None],
) -> None:
    """Ask about clips / symlinks before `op` (cut, move, rename) touches `paths`.

    done(policy) with policy "" (nothing found), "y" (go, leave links), "U" (update) or
    "R" (replace); cancel() otherwise. Enter and Esc both answer "cancel".
    """
    ask = fm.ui.console.ask
    _arm()
    clips = find_clips(paths)
    subjects = [path for path in paths if _under_roots(path)]
    hits = find_hits(subjects, LOCK_WAIT) if subjects else []
    if hits is None:
        ask(
            f"link scan unavailable (cache is warming) -- {op} anyway? (y / C=cancel)",
            lambda ans: done("y") if ans in ("y", "Y") else cancel(),
            ("c", "C", "y", "Y"),
        )
        return
    hits = _drop_moving(hits, paths)
    if not hits and not clips:
        return done("")
    _recovery(
        op,
        [f"path {p}" for p in paths]
        + [f"link {h.link} -> {_safe_readlink(h.link)}" for h in hits]
        + [f"clip {c}" for c in clips],
    )
    _print_links(fm, op, hits)
    parts = []
    if hits:
        parts.append(f"{len(hits)} symlink(s): {_brief(h.link for h in hits)}")
    if clips:
        parts.append(f"{len(clips)} clip(s)")
    if hits:
        text = (
            " + ".join(parts)
            + f" -- {op}? (y=leave / U=update / R=replace / n=dashboard / C=cancel)"
        )
        choices: tuple[str, ...] = ("c", "C", "y", "Y", "n", "N", "U", "R")
    else:
        text = parts[0] + f" -- {op} anyway? (y / C=cancel)"
        choices = ("c", "C", "y", "Y")

    def answer(ans: str) -> None:
        if ans in ("U", "R"):
            done(ans)
        elif ans in ("y", "Y"):
            _acknowledge(hit.link for hit in hits)
            done("y")
        else:
            if ans in ("n", "N"):
                dest = fs.join(DASHBOARD_ROOT, fs.basename(paths[0]))
                make_dashboard(fm, [hit.link for hit in hits], dest)
            cancel()

    ask(text, answer, choices)


def _safe_like(dst: str, taken: set[str]) -> str:
    """ranger's get_safe_path(), also treating names taken earlier in the same batch as existing."""

    def exists(path: str) -> bool:
        return fs.exists(path) or path in taken

    if not exists(dst):
        return dst
    if not dst.endswith("_"):
        dst += "_"
        if not exists(dst):
            return dst
    n = 0
    while exists(dst + str(n)):
        n += 1
    return dst + str(n)


def _predict_moves(
    paths: Sequence[str], dest: str, overwrite: bool, make_safe_path
) -> dict[str, str]:
    """Where ranger's mover will put each path (same rule as shutil_generatorized.move)."""
    moves: dict[str, str] = {}
    taken: set[str] = set()
    for old in paths:
        real = fs.join(dest, fs.basename(old))
        if overwrite:
            new = real
        elif make_safe_path is get_safe_path:
            new = _safe_like(real, taken)
        else:
            new = make_safe_path(real)
            if new in taken:
                _LOG.warning("cannot predict destination of %s", old)
                continue
        taken.add(new)
        moves[old] = new
    return moves


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
            () if DASHBOARD_ROOT in cls.roots() else (DASHBOARD_ROOT,)
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
            exts = "|".join(("html",) + PICS_EXTS)
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
        return REFRESH if REFRESH in ("validate", "visited", "none") else "validate"

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
            else fs.join(DASHBOARD_ROOT, self.fm.thisfile.relative_path)
        )
        return make_dashboard(self.fm, matches, dest)

    def _yank(self, matches: list[str]) -> None:
        subprocess.run(["xci"], input="\n".join(matches), text=True, check=False)

    def _jump(self, matches: list[str]) -> None:
        current = self.fm.thisfile.path
        rotate = "r" in self._args()[0]
        if rotate and current in matches:
            target = matches[(matches.index(current) + 1) % len(matches)]
        else:
            current_real = fs.realpath(current)
            dashboard_match = next(
                (
                    fs.join(self.fm.thisdir.path, entry.basename)
                    for entry in self.fm.thisdir.files or ()
                    if entry.is_link and fs.realpath(entry.path) == current_real
                ),
                None,
            )
            target = dashboard_match or matches[0]
        self.fm.select_file(target)
        if "o" in self._args()[0]:
            self.fm.move(right=1)
        if len(matches) > 1:
            target_real = fs.realpath(target)
            position = next(
                (
                    index
                    for index, match in enumerate(matches)
                    if match == target or fs.realpath(match) == target_real
                ),
                0,
            )
            self.fm.notify(f"MULTI ({position + 1}/{len(matches)})")

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

        highlight = highlight_rest if PRINT_HIGHLIGHT == "rest" else highlight_needle

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
        """Compare dangling links with the previous check first (when the cache is refreshed
        anyway), tell about new ones, then run the command."""
        try:
            flags, _ = self._args()
        except ValueError as error:
            self.fm.notify(f"vdsym: {error}", bad=True)
            return
        _arm()
        new = None
        if "N" not in flags and self._mode(flags) in ("validate", "rescan"):
            new = check_dangling(self.fm, notify=False)
        if not new:
            return self._execute()
        # Enter = continue, Esc = abort the command
        self.fm.ui.console.ask(
            f"{len(new)} symlink(s) newly dangling: {_brief(map(fs.basename, new))}"
            " (:display_log) -- Enter=continue / Esc=abort / l=list / U=re-point",
            lambda ans: self._after_dangling(ans, new),
            ("c", "q", "l", "U"),
        )

    def _after_dangling(self, answer: str, new: list[str]) -> None:
        if answer == "q":
            return
        if answer == "l":
            _list_dangling(self.fm, new)
        elif answer == "U":
            _repoint_unique(self.fm, new)
        self._execute()

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
                self._jump(matches)
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
            self._jump(matches)
        else:
            self.fm.select_file(matches[0])
            if "o" in flags:
                self.fm.move(right=1)
        self._report_kpi(started, operation)


# --------------------------------------------------------------------------- #
# :delete
# --------------------------------------------------------------------------- #


class _FmProxy:
    """fm as seen by one :delete instance: delete() redirected, rest passed through."""

    def __init__(self, fm, delete) -> None:
        self._fm = fm
        self.delete = delete

    def __getattr__(self, name):
        return getattr(self._fm, name)


# OR: map dD eval fm.set_clipboard(fm.thisfile.basename.encode('utf-8')); cmd('delete')
class delete(_default_delete):
    """:delete

    Copy selected file names to the clipboard before deleting them.
    Deletion is skipped when clipboard copy fails.
    Asks first when the files have sibling clips or symlinks leading to them (files, symlinks
    and directories inside the VD roots). Enter/Esc on the prompts always cancel.
    """

    def execute(self) -> None:
        self._real_fm = self.fm
        self.fm = _FmProxy(self._real_fm, self._guarded_delete)  # this command only
        super().execute()

    # -- steps ---------------------------------------------------------------- #

    def _guarded_delete(self, files: Sequence[str] | None = None) -> None:
        if files is None:
            files = [f.path for f in self._real_fm.thistab.get_selection()]
        cwd = self._real_fm.thisdir.path
        paths = [fs.join(cwd, f) for f in files]
        clips = self._clips(paths)
        if not clips:
            return self._check_links(files, paths)
        self._ask(
            f"{len(clips)} clip(s)"
            " -- delete anyway? (y/N)",
            ("n", "N", "y", "Y"),
            lambda ans: ans in ("y", "Y") and self._check_links(files, paths),
        )

    def _check_links(self, files: Sequence[str], paths: Sequence[str]) -> None:
        _arm()
        subjects = [path for path in paths if _under_roots(path)]
        hits = find_hits(subjects, LOCK_WAIT) if subjects else []
        if hits is None:
            return self._ask(
                "link scan unavailable (cache is warming) -- delete anyway? (y / C=cancel)",
                ("c", "C", "y", "Y"),
                lambda ans: ans in ("y", "Y") and self._copy_and_delete(files),
            )
        links = [hit.link for hit in _drop_moving(hits, paths)]
        if not links:
            return self._copy_and_delete(files)
        _recovery(
            "delete",
            [f"path {p}" for p in paths]
            + [f"link {l} -> {_safe_readlink(l)}" for l in links],
        )
        first = fs.basename(subjects[0])
        # Enter answers choices[0], Esc choices[1]: both must be "cancel"
        self._ask(
            f"{len(links)} symlink(s): {_brief(links)}"
            " -- delete? (y / n=dashboard / C=cancel)",
            ("c", "C", "y", "Y", "n", "N"),
            lambda ans: self._on_links(ans, files, links, first),
        )

    def _on_links(
        self, answer: str, files: Sequence[str], links: list[str], first: str
    ) -> None:
        if answer in ("y", "Y"):
            _acknowledge(links)
            self._copy_and_delete(files)
        elif answer in ("n", "N"):
            make_dashboard(self._real_fm, links, fs.join(DASHBOARD_ROOT, first))

    def _copy_and_delete(self, files: Sequence[str]) -> None:
        names = [fs.basename(file) for file in files]
        if self._copy_names(names):
            self._real_fm.delete(files)
        else:
            self._real_fm.notify("Could not copy file name to clipboard", bad=True)

    # -- helpers ---------------------------------------------------------------- #

    def _ask(self, text: str, choices: tuple[str, ...], callback) -> None:
        self._real_fm.ui.console.ask(text, callback, choices)

    def _copy_names(self, names: Sequence[str]) -> bool:
        try:
            process = subprocess.run(
                ["xci"],
                input="\n".join(names),
                text=True,
                capture_output=True,
                check=False,
            )
        except OSError:
            return False
        return process.returncode == 0

    _clips = staticmethod(find_clips)


class rename(_default_rename):
    """:rename <newname>

    Asks first when clips or symlinks depend on the old name (see _guard_move).
    """

    def execute(self) -> None:
        fm, cursor, new_name = self.fm, self.fm.thisfile, self.rest(1)
        if (
            not new_name
            or not cursor
            or new_name == cursor.relative_path
            or fs.lexists(new_name)
        ):
            return super().execute()  # stock code reports these itself
        old = fs.abspath(cursor.path)
        new = fs.abspath(fs.join(fm.thisdir.path, new_name))

        def done(policy: str) -> None:
            job = None
            if policy in ("U", "R"):
                hits = _drop_moving(find_hits([old], LOCK_WAIT, True) or [], [old])
                _recovery("rename", [f"{old} -> {new}"])
                if hits:
                    job = _MoveJob(fm, {old: new}, {old: policy}, hits)
            super(rename, self).execute()
            if job:
                job.finish()

        _guard_move(fm, [old], "rename", done, lambda: None)
        return None


# --------------------------------------------------------------------------- #
# dangling symlinks (what can't be hooked is caught afterwards)
# --------------------------------------------------------------------------- #


def _busy(fm) -> bool:
    """ranger is copying / moving / deleting: links may dangle for a moment, check later."""
    loader = getattr(fm, "loader", None)
    return bool(loader and loader.has_work())


def _dangling_now(wait: float) -> set[str] | None:
    """Every symlink under the VD roots that leads nowhere (None: cache busy for `wait` s)."""
    if not _cache.lock.acquire(timeout=wait):
        return None
    try:
        links = _cache.ensure(vdsym.roots(), "validate", "links").index.links
        return {link for link in links if _dangling(link)}
    finally:
        _cache.lock.release()


def check_dangling(
    fm=None, notify: bool = True, wait: float = LOCK_WAIT
) -> list[str] | None:
    """Compare the dangling links with the previous check; log the new ones (details for
    :display_log) and notify shortly. The first check is the baseline. Returns the new links,
    or None when it could not run now (cache busy / ranger busy): nothing is lost, the next
    check simply compares against the older state."""
    mon = _cache.monitor
    if not DANGLING_MONITOR or (fm is not None and _busy(fm)):
        return None
    if not _cache.lock.acquire(timeout=wait):
        return None
    try:  # one step: snapshot + comparison (the lock is re-entrant)
        current = _dangling_now(wait)
        if current is None:
            return None
        previous, mon.known = mon.known, current
        mon.total = len(current)
    finally:
        _cache.lock.release()
    if previous is None:
        _LOG.info("vdsym: %d dangling symlink(s) at start", len(current))
        return []
    new = sorted(current - previous)
    if new:
        _LOG.warning(
            "%d symlink(s) newly dangling (%d in total):", len(new), len(current)
        )
        for link in new[:200]:
            _LOG.warning("  %s -> %s", link, _safe_readlink(link))
        if len(new) > 200:
            _LOG.warning("  ... and %d more", len(new) - 200)
        if notify and fm is not None:
            fm.notify(
                f"{len(new)} symlink(s) newly dangling -- see :display_log", bad=True
            )
    return new


def _arm(delay: float | None = None) -> None:
    """(Re)start the one-shot timer: it fires after `delay` s without further VD activity."""
    if DANGLING_MONITOR:
        _cache.monitor.deadline = time.monotonic() + (
            DANGLING_QUIET if delay is None else delay
        )


def _tick() -> None:
    """Ranger's only timer: its main loop calls Loader.work() at least every idle_delay (2 s)."""
    mon = _cache.monitor
    if mon.deadline is None or time.monotonic() < mon.deadline:
        return
    mon.deadline = None
    try:
        if check_dangling(_cache.fm) is None:
            _arm(5.0)  # ranger or the cache was busy: try again shortly
    except Exception:  # noqa: BLE001 - never break ranger's main loop
        _LOG.exception("vdsym dangling check failed")


def _candidates(links: Iterable[str]) -> dict[str, list[str]]:
    """Real files (not links) with the basename a dangling link used to point at."""
    with _cache.lock:
        index = _cache.ensure(vdsym.roots(), "none").index
        return {
            link: [
                path
                for path in index.names.get(
                    fs.basename((_safe_readlink(link) or "").rstrip("/")), ()
                )
                if path not in index.links and not _gone(path)
            ]
            for link in links
        }


def _repoint_unique(fm, links: Iterable[str]) -> None:
    """Re-point every link that has exactly one candidate to it."""
    todo = {
        link: found[0] for link, found in _candidates(links).items() if len(found) == 1
    }
    _recovery(
        "dangling-update",
        [f"{link} -> {candidate}" for link, candidate in todo.items()],
    )
    done = failed = 0
    for link, candidate in todo.items():
        try:
            _swap_link(
                link, _link_text(link, _safe_readlink(link) or "", candidate, "")
            )
            done += 1
        except OSError as error:
            failed += 1
            _LOG.warning("dangling update %s: %s", link, error)
    _cache.touch(todo)
    _cache.monitor.known = (_cache.monitor.known or set()) - set(todo)
    fm.notify(
        f"re-pointed {done} dangling link(s)"
        + (f", {failed} failed" if failed else ""),
        bad=bool(failed),
    )


def _list_dangling(fm, links: list[str]) -> None:
    lines = [f"{len(links)} dangling symlink(s):"]
    for link, found in _candidates(links).items():
        lines.append(f"{link} -> {_safe_readlink(link)}")
        lines += [f"    candidate: {path}" for path in found[:3]]
    fm.execute_command("printf '%s\\n' " + shell_quote("\n".join(lines)), flags="-w")


class dangling(Command):
    """:dangling [update]

    Lists the symlinks under the VD roots that lead nowhere, each with the real files of the
    same basename (candidates). `update` re-points every link that has exactly one candidate,
    after asking.
    """

    def execute(self) -> None:
        fm, mode = self.fm, self.arg(1)
        if mode not in ("", "update"):
            return fm.notify("Syntax: dangling [update]", bad=True)
        current = _dangling_now(LOCK_WAIT)
        if current is None:
            return fm.notify("cache is busy (warming), try again in a moment", bad=True)
        links = sorted(current)
        if not links:
            return fm.notify("no dangling symlinks")
        if mode == "":
            return _list_dangling(fm, links)
        return fm.ui.console.ask(
            f"re-point the dangling links that have exactly one candidate ({len(links)} dangling)?"
            " (y / C=cancel)",
            lambda ans: ans in ("y", "Y") and _repoint_unique(fm, links),
            ("c", "C", "y", "Y"),
        )


# --------------------------------------------------------------------------- #
# cd signal: lazy warm-up + "visited" bookkeeping (a signal, NOT a Tab.enter_dir wrapper:
# history_navi inspects the caller frame of enter_dir and must stay the outermost wrapper)
# --------------------------------------------------------------------------- #


def _warm() -> None:
    try:
        roots = vdsym.roots()
        _cache.ensure(roots)
        _cache.ensure(roots[:1])  # view-only index used by --modifiers=view
        if _cache.monitor.known is None:
            check_dangling(None)  # baseline: what dangles already is not news
    except Exception:  # noqa: BLE001 - never break ranger
        _LOG.exception("vdsym warm-up failed")


def _on_cd(path: str) -> None:
    if not _under_roots(path):
        return
    _cache.visited.add(path)
    _cache.visited.add(fs.realpath(path))
    _arm()
    if WARM_ON_CD and not _cache.warmed:
        _cache.warmed = True
        threading.Thread(target=_warm, name="vdsym-warm", daemon=True).start()


def _on_cd_signal(signal) -> None:
    new = getattr(signal, "new", None)
    if new is not None:
        try:
            _on_cd(new.path)
        except Exception:  # noqa: BLE001
            _LOG.exception("vdsym cd handler failed")


def _bind_cd(fm) -> None:
    if fm is None or getattr(fm, "_vdsym_cd", None) == _cache.stamp:
        return
    fm._vdsym_cd = _cache.stamp
    _cache.fm = fm
    fm.signal_bind("cd", _on_cd_signal)


# --------------------------------------------------------------------------- #
# patches of ranger internals (idempotent, re-exec safe, skipped if ranger differs)
# --------------------------------------------------------------------------- #

_STATE = types.SimpleNamespace(job=None, policy={})  # policy: path -> "" | y | U | R


def _patch(owner, name: str, make) -> None:
    originals = sys.modules["_vdsym_shared"].orig
    original = originals.setdefault((owner, name), getattr(owner, name))
    setattr(owner, name, make(original))


def _make_copy(orig):
    def copy(self, mode="set", narg=None, dirarg=None):
        if mode == "set":
            _STATE.policy.clear()
        return orig(self, mode=mode, narg=narg, dirarg=dirarg)

    return copy


def _make_uncut(orig):
    def uncut(self):
        _STATE.policy.clear()
        return orig(self)

    return uncut


def _make_cut(orig):
    def cut(self, mode="set", narg=None, dirarg=None):
        orig(
            self, mode=mode, narg=narg, dirarg=dirarg
        )  # its self.copy() resets the policy
        if not self.do_cut:
            return
        fresh = [f.path for f in self.copy_buffer if f.path not in _STATE.policy]
        if not fresh:
            return

        def done(policy: str) -> None:
            for path in fresh:
                _STATE.policy[path] = policy

        def cancel() -> None:
            gone = set(fresh)
            self.copy_buffer = {f for f in self.copy_buffer if f.path not in gone}
            self.do_cut = bool(self.copy_buffer)
            self.ui.browser.main_column.request_redraw()

        _guard_move(self, fresh, "cut", done, cancel)

    return cut


def _make_paste(orig):
    def paste(
        self, overwrite=False, append=False, dest=None, make_safe_path=get_safe_path
    ):
        target = self.thistab.path if dest is None else dest
        if not self.do_cut or not self.copy_buffer:
            return orig(
                self,
                overwrite=overwrite,
                append=append,
                dest=dest,
                make_safe_path=make_safe_path,
            )
        paths = [f.path for f in self.copy_buffer]

        def go() -> None:
            wanted = {p: _STATE.policy.pop(p, "") for p in paths}
            active = {p: pol for p, pol in wanted.items() if pol in ("U", "R")}
            job = None
            if active and fs.isdir(target):
                moves = _predict_moves(list(active), target, overwrite, make_safe_path)
                hits = _drop_moving(
                    find_hits(list(moves), LOCK_WAIT, True) or [], paths
                )
                _recovery("paste", [f"{old} -> {new}" for old, new in moves.items()])
                if hits and moves:
                    job = _MoveJob(self, moves, active, hits)
            _STATE.job = job
            try:
                orig(
                    self,
                    overwrite=overwrite,
                    append=append,
                    dest=target,
                    make_safe_path=make_safe_path,
                )
            finally:
                _STATE.job = None

        fresh = [p for p in paths if p not in _STATE.policy]
        if not fresh:
            return go()

        def done(policy: str) -> None:
            for path in fresh:
                _STATE.policy[path] = policy
            go()

        _guard_move(self, fresh, "move", done, lambda: None)
        return None

    return paste


def _make_work(orig):
    def work(self, *args, **kwargs):
        result = orig(self, *args, **kwargs)
        _tick()
        return result

    return work


def _make_loader_init(orig):
    def __init__(self, *args, **kwargs):
        self._vdsym_job = _STATE.job
        orig(self, *args, **kwargs)

    return __init__


def _make_loader_generate(orig):
    def generate(self):
        job = getattr(self, "_vdsym_job", None)
        try:
            yield from orig(self)
        finally:  # completion, error or cancel: reconcile what really moved
            if job is not None:
                job.finish()

    return generate


def _install() -> None:
    try:
        import ranger
        import ranger.api
        from ranger.core.actions import Actions
        from ranger.core.loader import CopyLoader, Loader

        for owner, name, make in (
            (Actions, "copy", _make_copy),
            (Actions, "uncut", _make_uncut),
            (Actions, "cut", _make_cut),
            (Actions, "paste", _make_paste),
            (CopyLoader, "__init__", _make_loader_init),
            (CopyLoader, "generate", _make_loader_generate),
            (Loader, "work", _make_work),
        ):
            _patch(owner, name, make)
        _bind_cd(getattr(ranger, "fm", None))
        if not getattr(ranger.api.hook_init, "_vdsym", False):
            previous = ranger.api.hook_init

            def hook_init(fm):
                _bind_cd(fm)
                return previous(fm)

            hook_init._vdsym = True  # type: ignore[attr-defined]
            ranger.api.hook_init = hook_init
    except Exception:  # noqa: BLE001 - a different ranger must not break the whole plugin
        _LOG.exception("vdsym: move guards / cd signal not installed")


_install()
