"""
dcsize — ranger plugin for recursive size calculation with linemode/sort/filter/undo.

════════════════════════════════════════════════════════════════════════════════
MODES
────────────────────────────────────────────────────────────────────────────────
  file   no-symlink  regular files only; all symlinks skipped at every level
  all    all         regular files + symlinks; file-symlinks counted with target
                 size; dir-symlinks descended with (dev,ino) loop guard;
                 broken links counted 1 with link size
  video          only regular (non-link) files in EXTS whose first video
                 track format matches SPEC; configured by codec= argument

════════════════════════════════════════════════════════════════════════════════
LINEMODES
────────────────────────────────────────────────────────────────────────────────
  dc{file,all,video} applied ONLY to dir entries in current pwd.
  Files in pwd: linemode never changed by dc*.
  Contents of subdirs: never touched.
  Format: dcfile dirs → "(*n) size"   dcall dirs → "(n) size".
  dcvideo dirs → "(n*codec) size" or "(n!codec) size".
  Files → "size".  n = matched file count.
  cursor / 1dc*: only the entry under cursor updated; others unchanged.
  Without explicit selection, only entries visible after current filters are used.
  Explicit .get_selection() overrides the visible-entry set.

════════════════════════════════════════════════════════════════════════════════
SORTING
────────────────────────────────────────────────────────────────────────────────
  sort keys dc{file,all,video}: largest first; uncomputed entries sort to end (size 0).
  Activated by the sort argument; setlocal sort is applied to current dir.
  Restored by dcu.
  Restore order: setlocal (if original sort was local) → fallback to set.

════════════════════════════════════════════════════════════════════════════════
FILTERING  (DcFilter — at most one per pwd, mode updated in-place)
────────────────────────────────────────────────────────────────────────────────
  mode file/all — always applied when running dcfile/dcall:
    dirs:  hidden only with hide_empty and computed count == 0
    files: always pass  →  unhides any files hidden by a previous dcvideo
  mode video — applied only when filter argument given:
    dirs:  hidden only with hide_empty and computed count == 0
    files: hidden if codec does not match SPEC
  Switching file/all → video: DcFilter.mode updated, file-hiding reactivated.
  Switching video → file/all: DcFilter.mode updated, file-hiding cleared.
  dcvideo without filter: any existing DcFilter removed.

════════════════════════════════════════════════════════════════════════════════
EMPTY DIRECTORIES
────────────────────────────────────────────────────────────────────────────────
  hide_empty argument enables hiding dirs with computed count == 0.
  Without hide_empty, zero-size dirs stay visible.
  File-hiding in video mode is independent of hide_empty.

════════════════════════════════════════════════════════════════════════════════
UNDO  (dcu → :dcsize undo)
────────────────────────────────────────────────────────────────────────────────
  Snapshot taken before the FIRST dc* run in a pwd; subsequent runs reuse
  the same snapshot so dcu always reverts to the pre-dc* state.
  Restores:
    • pwd and visible child sort+sort_reverse settings, pwd filter_stack
    • per-entry linemode and SIZES for every item in pwd (all three modes)
    • filter_stack of every already-loaded subdir of pwd
  Clears snapshot on restore; next dc* re-snapshots fresh.
  Notifies if no snapshot exists for this pwd.

════════════════════════════════════════════════════════════════════════════════
CURSOR MODE
────────────────────────────────────────────────────────────────────────────────
  Triggered by cursor argument or count prefix (1dcfile, 2dcvideo, …).
  Computes only the item under the cursor; only its linemode is updated.
  If sort or filter is requested, all cwd files are computed too.

════════════════════════════════════════════════════════════════════════════════
CODEC ARGUMENT
────────────────────────────────────────────────────────────────────────────────
  codec=a,b        match any format in set (case-insensitive)
  codec=!a,!b      exclude listed formats; pass anything else
  Mixed:           codec=hevc,!avc
  Compared against pymediainfo first video track Format field.
  Changing codec spec clears all cached v SIZES.
  Default: AV1

════════════════════════════════════════════════════════════════════════════════
PERSISTENT CACHE
────────────────────────────────────────────────────────────────────────────────
  vdprobe sqlite cache (vdprobe.CACHE_PATH), shared with vddur + the CLI:
  • per file (codec/duration): keyed by inode, valid while mtime_ns+size match;
    survives restarts and moving/renaming files.
  • per directory (own entries: subdirs, symlinks, .mp4 names, regular-file total):
    keyed by dir inode, valid while the DIRECTORY mtime is unchanged, so an
    unchanged directory costs ONE stat instead of a readdir + stat per file.
    video mode still stats every .mp4 (exact for in-place re-encodes);
    file/all totals are trusted for TRUST seconds (in-place edits of a file do
    not change its directory's mtime) -- add `fresh` to bypass the directory cache.
  SIZES and SNAP are in-memory only.

════════════════════════════════════════════════════════════════════════════════
MAPPINGS  (rc.conf)
────────────────────────────────────────────────────────────────────────────────
  map dcf  dcsize file sort
  map dca  dcsize all sort
  map dcv  dcsize video sort filter codec=AV1
  map dcF  dcsize file sort hide_empty
  map dcA  dcsize all sort hide_empty
  map dcV  dcsize video sort filter hide_empty codec=AV1
  map dcu  dcsize undo

════════════════════════════════════════════════════════════════════════════════
KNOWN LIMITATIONS
────────────────────────────────────────────────────────────────────────────────
  • Hardlinks double-counted.
  • file/all totals may lag in-place file edits by up to TRUST (use `fresh`).
  • Only EXTS files codec-checked (default: .mp4).
  • UI blocks during computation; first dcvideo on cold cache is slow.
  • SIZES and SNAP lost on restart.
  • setlocal path restore may break on paths with spaces (ranger cmd parser).
  • fm.settings._local is private; check on ranger upgrades.
════════════════════════════════════════════════════════════════════════════════
"""

import os
import re
import stat
import sys
import time
from concurrent.futures import FIRST_COMPLETED, ThreadPoolExecutor, wait
from threading import Event

from ranger.api import register_linemode
from ranger.api.commands import Command
from ranger.container.directory import Directory
from ranger.core.linemode import LinemodeBase
from ranger.core.loader import Loadable
from ranger.ext.human_readable import human_readable

try:
    # ranger imports plugins as `plugins.<name>` with the confdir on sys.path while it loads them
    from plugins import vdprobe
except ImportError:
    import vdprobe  # fallback: vdprobe.py somewhere on PYTHONPATH

MODES = ("file", "all", "video")
EXTS = (".mp4",)
SIZES = {m: {} for m in MODES}  # mode -> {path: (nfiles, bytes)}
SPEC = (frozenset({"av1"}), frozenset())  # (wanted, unwanted) codec sets
SNAP = {}  # pwd.path -> snapshot dict

_MAX_WORKERS = 8
TRUST = (
    24 * 3600
)  # file/all: cached directory totals are re-verified after this many seconds
_FRESH = False  # `fresh` argument: ignore cached directory data (still refreshes it)
_CACHE_HITS = 0
_CACHE_MISSES = 0
_DIR_HITS = 0
_DIR_SCANS = 0


class _Cancel(Exception):
    pass


class _DcsizeLoader(Loadable):
    progressbar_supported = True

    def __init__(self, fm, todo, mode, on_result, on_finish):
        self.fm = fm
        self.todo = todo
        self.mode = mode
        self.on_result = on_result
        self.on_finish = on_finish
        self.cancelled = Event()
        self._vdsym_monitor = None
        self.percent = 0
        Loadable.__init__(self, self.generate(), "dcsize: calculating")

    def destroy(self):
        self.cancelled.set()
        super().destroy()
        generator = self.load_generator
        if generator is not None:
            generator.close()

    def generate(self):
        if not self.todo:
            self.on_finish()
            return
        self._vdsym_monitor = _pause_vdsym_monitor(self.mode)
        ex = ThreadPoolExecutor(max_workers=min(_MAX_WORKERS, len(self.todo)))
        try:
            jobs = {
                ex.submit(_tree, f.path, self.mode, True, self.cancelled): f
                for f in self.todo
            }
            pending = set(jobs)
            done_count = 0
            while pending and not self.cancelled.is_set():
                finished, pending = wait(
                    pending, timeout=0.05, return_when=FIRST_COMPLETED
                )
                if not finished:
                    waiting = ", ".join(
                        os.path.basename(jobs[future].path) for future in list(pending)[:2]
                    )
                    self.description = (
                        f"dcsize: {done_count}/{len(self.todo)}; "
                        f"pending {len(pending)} ({waiting})"
                    )
                    yield
                    continue
                for future in finished:
                    if self.cancelled.is_set():
                        break
                    f = jobs[future]
                    self.on_result(f, future.result())
                    done_count += 1
                    self.percent = done_count * 100.0 / len(self.todo)
                    self.description = f"dcsize: {done_count}/{len(self.todo)}"
                    yield
            if self.cancelled.is_set():
                for future in pending:
                    future.cancel()
                return
            self.on_finish()
        finally:
            ex.shutdown(
                wait=not self.cancelled.is_set(),
                cancel_futures=self.cancelled.is_set(),
            )
            _restore_vdsym_monitor(self._vdsym_monitor)


# ── MediaInfo cache ───────────────────────────────────────────────────────────


def _pause_vdsym_monitor(mode):
    if mode != "video":
        return None
    try:
        vdsym = sys.modules.get("vdsym")
        if vdsym is None:
            vdsym = sys.modules.get("ranger.plugins.vdsym")
        if vdsym is None:
            return None

        old = vdsym.DANGLING_MONITOR
        vdsym.DANGLING_MONITOR = False
        return vdsym, old
    except Exception:
        return None


def _restore_vdsym_monitor(state):
    if state is None:
        return
    vdsym, old = state
    vdsym.DANGLING_MONITOR = old
    if old:
        try:
            vdsym._arm(30.0)
        except Exception:
            pass


def _vfmt(p, st):
    """first video codec of regular file p ('' if none); st = its stat"""
    r, _ = vdprobe.lookup(p, st)
    return r[1].partition(" / ")[0] if r else ""


# ── codec spec ────────────────────────────────────────────────────────────────


def _parse_spec(s):
    pos, neg = set(), set()
    for t in s.lower().split(","):
        t = t.strip()
        if t:
            (neg if t.startswith("!") else pos).add(t.lstrip("!"))
    return frozenset(pos), frozenset(neg)


def _match(fmt):
    pos, neg = SPEC
    fmt = fmt.lower()
    return bool(fmt) and (not pos or fmt in pos) and fmt not in neg


def _codec_label():
    pos, neg = SPEC
    parts = []
    if pos:
        parts.append("*" + ",".join(sorted(pos)))
    if neg:
        parts.append("!" + ",".join(sorted(neg)))
    return ",".join(parts)


# ── walk ──────────────────────────────────────────────────────────────────────


def _leaf(p, mode, st):
    if mode == "video" and not _match(_vfmt(p, st)):
        return 0, 0
    return 1, st.st_size


def _readdir(path, need_f, prev, cancelled):
    """one directory's own entries. need_f: also total the regular files (one stat each)."""
    subs, links, vn = [], [], []
    n = b = i = 0
    try:
        with os.scandir(path) as it:
            for e in it:
                i += 1
                if not i & 255 and cancelled is not None and cancelled.is_set():
                    raise _Cancel
                try:
                    if e.is_symlink():  # d_type: no syscall
                        links.append(e.name)
                    elif e.is_dir(follow_symlinks=False):
                        subs.append(e.name)
                    elif e.is_file(follow_symlinks=False):
                        name = e.name
                        if name.lower().endswith(EXTS):
                            vn.append(name)
                        if need_f:
                            n += 1
                            b += e.stat(follow_symlinks=False).st_size
                except OSError:
                    continue
    except OSError:
        pass
    if need_f:
        f, ft = (n, b), time.time()
    else:  # video pass: keep an earlier (still same-mtime) total
        f, ft = (prev["f"], prev["ft"]) if prev else (None, 0)
    return {
        "s": tuple(subs),
        "l": tuple(links),
        "v": (EXTS, tuple(vn)),
        "f": f,
        "ft": ft,
    }


def _dir(path, st, mode, cancelled):
    """cached facts about one directory, valid while its mtime is unchanged"""
    global _DIR_HITS, _DIR_SCANS
    ino, mt = st.st_ino, st.st_mtime_ns
    prev = None
    if not _FRESH:
        e = vdprobe.dir_get(ino)
        if e is not None and e[0] == mt:
            prev = e[1]
    need_f = mode != "video"
    if (
        prev is not None
        and prev["v"][0] == EXTS
        and (not need_f or (prev["f"] is not None and time.time() - prev["ft"] < TRUST))
    ):
        _DIR_HITS += 1
        return prev
    _DIR_SCANS += 1
    o = _readdir(path, need_f, prev, cancelled)
    vdprobe.dir_put(
        ino, mt, o
    )  # mt was read BEFORE the listing: a racing change just forces a rescan
    return o


def _scan(path, mode, seen, cancelled=None, st=None):
    """(count, bytes) of a directory tree. st = os.stat(path) if the caller has it."""
    if cancelled is not None and cancelled.is_set():
        return 0, 0
    try:
        if st is None:
            st = os.stat(path)
        o = _dir(path, st, mode, cancelled)
    except OSError:
        return 0, 0
    if mode == "video":
        n = size = 0
        media = []
        for i, name in enumerate(o["v"][1]):  # regular .mp4 names; each still stat'ed => exact
            if not i & 255 and cancelled is not None and cancelled.is_set():
                raise _Cancel
            p = path + "/" + name
            try:
                s = os.lstat(p)
            except OSError:
                continue
            if s.st_mode & 0o170000 == 0o100000:
                media.append((p, s))
        results = vdprobe.many([p for p, _ in media])
        for p, s in media:
            r = results.get(p)
            fmt = r[1].partition(" / ")[0] if r else ""
            if _match(fmt):
                n += 1
                size += s.st_size
    else:
        n, size = o["f"]
    for i, name in enumerate(o["s"]):
        if not i & 255 and cancelled is not None and cancelled.is_set():
            raise _Cancel
        p = path + "/" + name
        try:
            s = os.stat(p)
        except OSError:
            continue
        key = (s.st_dev, s.st_ino)
        if key in seen:
            continue
        seen.add(key)
        c, z = _scan(p, mode, seen, cancelled, s)
        n += c
        size += z
    if mode == "all":  # symlinks: re-stat every time (targets live elsewhere)
        for i, name in enumerate(o["l"]):
            if not i & 255 and cancelled is not None and cancelled.is_set():
                raise _Cancel
            p = path + "/" + name
            try:
                s = os.stat(p)
            except OSError:  # broken: counted once with the link's own size
                try:
                    n, size = n + 1, size + os.lstat(p).st_size
                except OSError:
                    pass
                continue
            if s.st_mode & 0o170000 == 0o040000:
                key = (s.st_dev, s.st_ino)
                if key in seen:
                    continue
                seen.add(key)
                c, z = _scan(p, mode, seen, cancelled, s)
            else:
                c, z = 1, s.st_size
            n += c
            size += z
    return n, size


def _scan_video_parallel(path, cancelled=None, st=None):
    """Sequential branch scan; top-level loader already supplies parallelism."""
    return _scan(path, "video", set(), cancelled, st)


def _tree(path, mode, parallel=False, cancelled=None):
    """Top-level: symlinked dirs descended in every mode."""
    try:
        lst = os.lstat(path)
        link = stat.S_ISLNK(lst.st_mode)
        try:
            st = os.stat(path) if link else lst
        except OSError:
            return (1, lst.st_size) if mode == "all" else (0, 0)
        if stat.S_ISDIR(st.st_mode):
            if parallel and mode == "video":
                return _scan_video_parallel(path, cancelled, st)
            return _scan(path, mode, {(st.st_dev, st.st_ino)}, cancelled, st)
        if (link and mode != "all") or not stat.S_ISREG(st.st_mode):
            return 0, 0
        if mode == "video" and not path.lower().endswith(EXTS):
            return 0, 0
        return _leaf(path, mode, st)
    except (OSError, _Cancel):
        return 0, 0


def _get(path, mode):
    r = SIZES[mode].get(path)
    if r is None:
        r = SIZES[mode][path] = _tree(path, mode)
    return r


# ── filter ────────────────────────────────────────────────────────────────────


class DcFilter:
    """
    Single filter instance per pwd; mode swapped in-place on mode switch.
    file/all: files always pass; dirs optionally hidden if count==0.
    video:     files pass only if codec matches SPEC; dirs optionally hidden if count==0.
    """

    def __init__(self, mode, hide_empty=False):
        self.mode = mode
        self.hide_empty = hide_empty

    def __call__(self, fobj):
        if fobj.is_directory:
            if not self.hide_empty:
                return True
            r = SIZES[self.mode].get(fobj.path)
            return r is None or r[0] > 0  # unknown → pass; computed empty → hide
        if self.mode == "video":
            return _get(fobj.path, "video")[0] > 0
        return True  # file/all: all files pass

    def __str__(self):
        return f"<Filter: dc{self.mode}>"

    def decompose(self):
        return [self]


def _set_filter(d, mode, hide_empty):
    """Update existing DcFilter in-place or append a new one."""
    for x in d.filter_stack:
        if isinstance(x, DcFilter):
            x.mode = mode
            x.hide_empty = hide_empty
            return
    d.filter_stack.append(DcFilter(mode, hide_empty))


def _remove_filter(d):
    for x in [x for x in d.filter_stack if isinstance(x, DcFilter)]:
        d.filter_stack.remove(x)


# ── snapshot ──────────────────────────────────────────────────────────────────


def _snap_sort(fm, d):
    """Detect local vs global sort. Returns (sort, rev, is_local).
    Uses fm.settings._local (private attr — check on ranger upgrades)."""
    try:
        local = fm.settings._local.get(d.path, {})
        if "sort" in local:
            return (
                local["sort"],
                local.get("sort_reverse", fm.settings.sort_reverse),
                True,
            )
    except (AttributeError, KeyError):
        pass
    return fm.settings.sort, fm.settings.sort_reverse, False


def _snap_local_sort(fm, path):
    local = getattr(fm.settings, "_localsettings", {}).get(re.escape(path) + "$", {})
    return {k: local[k] for k in ("sort", "sort_reverse") if k in local}


def _snapshot(fm, d):
    files = d.files_all or []
    sort, rev, is_local = _snap_sort(fm, d)
    paths = [d.path] + [f.path for f in files if f.is_directory]
    fdirs = getattr(fm, "directories", {})
    subdirs = {}
    for f in files:
        if f.is_directory and f.path in fdirs:
            sub = fdirs[f.path]
            subdirs[f.path] = {"filt": list(sub.filter_stack)}
    return dict(
        sort=sort,
        rev=rev,
        sort_is_local=is_local,
        local_sorts={p: _snap_local_sort(fm, p) for p in paths},
        filt=list(d.filter_stack),
        lm={f.path: f.linemode for f in files},
        sizes={m: {f.path: SIZES[m].get(f.path) for f in files} for m in MODES},
        subdirs=subdirs,
    )


def _restore_sort(fm, d, sn):
    sort = sn["sort"]
    rev = str(sn["rev"]).lower()  # 'true' / 'false'
    if sn.get("sort_is_local"):
        try:
            fm.execute_console(f"setlocal path={d.path} sort={sort}")
            fm.execute_console(f"setlocal path={d.path} sort_reverse={rev}")
            return
        except Exception:
            pass
    fm.execute_console(f"set sort={sort}")
    fm.execute_console(f"set sort_reverse={rev}")


def _set_local_sort(fm, path, sort):
    fm.execute_console(f"setlocal path={path} sort={sort}")
    fm.execute_console(f"setlocal path={path} sort_reverse=False")


def _restore_local_sorts(fm, sn):
    settings = getattr(fm.settings, "_localsettings", {})
    for path, saved in sn.get("local_sorts", {}).items():
        key = re.escape(path) + "$"
        if saved:
            local = settings.setdefault(key, {})
            local.update(saved)
        else:
            # Keep the empty pattern alive. Settings.get() can otherwise see
            # the key while this restore removes it and raise KeyError.
            local = settings.get(key)
            if local is not None:
                local.pop("sort", None)
                local.pop("sort_reverse", None)


# ── command ───────────────────────────────────────────────────────────────────


class dcsize(Command):
    """:dcsize <file|all|video|undo> [sort] [filter] [cursor] [fresh] [codec=…]
    count prefix (1dc*) implies cursor."""

    def _undo(self, d):
        sn = SNAP.pop(d.path, None)
        if sn is None:
            return self.fm.notify("dcsize: nothing to undo here")
        for f in d.files_all or []:
            if f.path in sn["lm"]:
                f.linemode = sn["lm"][f.path]
        for m, dd in sn["sizes"].items():
            for p, v in dd.items():
                if v is None:
                    SIZES[m].pop(p, None)
                else:
                    SIZES[m][p] = v
        d.filter_stack[:] = sn["filt"]
        fdirs = getattr(self.fm, "directories", {})
        for spath, sstate in sn.get("subdirs", {}).items():
            if spath in fdirs:
                sub = fdirs[spath]
                sub.filter_stack[:] = sstate["filt"]
                if sub.files_all is not None:
                    sub.refilter()
        _restore_local_sorts(self.fm, sn)
        _restore_sort(self.fm, d, sn)
        if d.files_all is not None:
            d.refilter()
        d.sort()
        self.fm.ui.redraw_main_column()

    def execute(self):
        global SPEC, _CACHE_HITS, _CACHE_MISSES, _DIR_HITS, _DIR_SCANS, _FRESH
        mode = self.arg(1)
        d = self.fm.thisdir

        if mode == "undo":
            return self._undo(d)
        if mode not in MODES:
            return self.fm.notify(
                "dcsize: mode must be file|all|video or undo", bad=True
            )
        if d.path not in SNAP:
            SNAP[d.path] = _snapshot(self.fm, d)

        opts, codec = set(), None
        for a in self.args[2:]:
            if a.startswith("codec="):
                codec = a[6:]
            else:
                opts.add(a)
        if mode == "video" and codec is not None:
            new = _parse_spec(codec)
            if new != SPEC:
                SPEC = new
                SIZES["video"].clear()

        _CACHE_HITS = _CACHE_MISSES = _DIR_HITS = _DIR_SCANS = 0
        if mode == "video":
            vdprobe.stats[:] = [0, 0]
        _FRESH = "fresh" in opts
        t0 = time.perf_counter()

        name = "dc" + mode
        cursor = self.quantifier is not None or "cursor" in opts
        # d.files is the post-filter view. Never submit d.files_all here.
        visible = list(d.files or [])
        marked = list(getattr(d, "marked_items", ()) or ())
        selected = list(self.fm.thistab.get_selection()) if marked else []
        base = selected or visible
        if marked:
            items = base
        elif cursor:
            items = [self.fm.thisfile] if self.fm.thisfile else []
        else:
            items = base
        dirs = [f for f in items if f.is_directory]
        files = (
            [f for f in base if not f.is_directory]
            if "sort" in opts or "filter" in opts
            else [f for f in items if not f.is_directory]
        )

        todo = dirs + files
        for f in dirs:
            f.linemode = name
        if "sort" in opts:
            _set_local_sort(self.fm, d.path, name)

        def on_result(f, result):
            SIZES[mode][f.path] = result
            ## DISABLED: sort-signal-storm
            ##   8 _set_local_sort calls -> 37,111 Directory.sort calls —> 37,111 signal callbacks
            # if f.is_directory:
            #     if "sort" in opts:
            #         child_sort = "sizeclips" if mode == "video" else name
            #         if f.path in getattr(self.fm, "directories", {}):
            #             _set_local_sort(self.fm, f.path, child_sort)

        def on_finish():
            vdprobe.flush()
            if mode == "video":
                _CACHE_HITS, _CACHE_MISSES = vdprobe.stats
            self.fm.notify(
                f"dcsize {mode}: {time.perf_counter() - t0:.1f}s  dirs {_DIR_HITS} cached/"
                f"{_DIR_SCANS} read"
                + (
                    f"  codec {_CACHE_HITS} hits/{_CACHE_MISSES} probed"
                    if mode == "video"
                    else ""
                )
            )
            hide_empty = "hide_empty" in opts
            had_dc_filter = any(isinstance(x, DcFilter) for x in d.filter_stack)
            if mode in ("file", "all"):
                if "filter" in opts or hide_empty:
                    _set_filter(d, mode, hide_empty)
                else:
                    _remove_filter(d)
            elif "filter" in opts:  # video with filter
                _set_filter(d, mode, hide_empty)
            else:  # video without filter
                _remove_filter(d)
            refresh = (
                "sort" in opts
                or "filter" in opts
                or hide_empty
                or had_dc_filter
            )
            if refresh and d.files_all is not None:
                d.refilter()
            if refresh:
                d.sort()
            self.fm.ui.redraw_main_column()

        self.fm.loader.add(_DcsizeLoader(self.fm, todo, mode, on_result, on_finish))


# ── linemodes + sort keys ─────────────────────────────────────────────────────


def _mk(mode):
    @register_linemode
    class _L(LinemodeBase):
        name = "dc" + mode

        def filetitle(self, fobj, metadata):
            return fobj.relative_path

        def infostring(self, fobj, metadata):
            r = SIZES[mode].get(fobj.path)
            if r is None:
                return ""
            s = human_readable(r[1])
            if not fobj.is_directory:
                return s
            if mode == "file":
                label = f"*{r[0]}"
            elif mode == "video":
                label = f"{r[0]}{_codec_label()}"
            else:
                label = str(r[0])
            return f"({label}) {s}"

    Directory.sort_dict["dc" + mode] = lambda f: -SIZES[mode].get(f.path, (0, 0))[1]


for _m in MODES:
    _mk(_m)

try:
    from ranger.container.settings import ALLOWED_VALUES

    ALLOWED_VALUES["sort"].extend("dc" + m for m in MODES)
except Exception:
    pass
