"""
dcsize — ranger plugin for recursive size calculation with linemode/sort/filter/undo.

════════════════════════════════════════════════════════════════════════════════
MODES
────────────────────────────────────────────────────────────────────────────────
  f  no-symlink  regular files only; all symlinks skipped at every level
  a  all         regular files + symlinks; file-symlinks counted with target
                 size; dir-symlinks descended with (dev,ino) loop guard;
                 broken links counted 1 with link size
  v  video       only regular (non-link) files in EXTS whose first video
                 track format matches SPEC; configured by codec= argument

════════════════════════════════════════════════════════════════════════════════
LINEMODES
────────────────────────────────────────────────────────────────────────────────
  dc{f,a,v} applied ONLY to dir entries in current pwd.
  Files in pwd: linemode never changed by dc*.
  Contents of subdirs: never touched.
  Format: dirs → "(n) size"   files → "size"   n = matched file count.
  cursor / 1dc*: only the entry under cursor updated; others unchanged.

════════════════════════════════════════════════════════════════════════════════
SORTING
────────────────────────────────────────────────────────────────────────────────
  sort keys dc{f,a,v}: largest first; uncomputed entries sort to end (size 0).
  Activated by the sort argument; restored by dcu.
  Restore order: setlocal (if original sort was local) → fallback to set.

════════════════════════════════════════════════════════════════════════════════
FILTERING  (DcFilter — at most one per pwd, mode updated in-place)
────────────────────────────────────────────────────────────────────────────────
  mode f/a — always applied when running dcf/dca:
    dirs:  hidden if HIDE_EMPTY and computed count == 0
    files: always pass  →  unhides any files hidden by a previous dcv
  mode v — applied only when filter argument given:
    dirs:  hidden if HIDE_EMPTY and computed count == 0
    files: hidden if codec does not match SPEC
  Switching f/a → v: DcFilter.mode updated, file-hiding reactivated.
  Switching v → f/a: DcFilter.mode updated, file-hiding cleared.
  dcv without filter: any existing DcFilter removed.

════════════════════════════════════════════════════════════════════════════════
HIDE_EMPTY
────────────────────────────────────────────────────────────────────────────────
  HIDE_EMPTY = True  (module-level; False disables dir-hiding globally)
  Dirs with computed count == 0 hidden in all modes.
  File-hiding in v mode is independent of HIDE_EMPTY.

════════════════════════════════════════════════════════════════════════════════
UNDO  (dcu → :dcsize undo)
────────────────────────────────────────────────────────────────────────────────
  Snapshot taken before the FIRST dc* run in a pwd; subsequent runs reuse
  the same snapshot so dcu always reverts to the pre-dc* state.
  Restores:
    • pwd sort+sort_reverse (local or global), pwd filter_stack
    • per-entry linemode and SIZES for every item in pwd (all three modes)
    • filter_stack of every already-loaded subdir of pwd
  Clears snapshot on restore; next dc* re-snapshots fresh.
  Notifies if no snapshot exists for this pwd.

════════════════════════════════════════════════════════════════════════════════
CURSOR MODE
────────────────────────────────────────────────────────────────────────────────
  Triggered by cursor argument or count prefix (1dcf, 2dcv, …).
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
  ~/.cache/ranger/dcsize.json  MediaInfo results keyed by path+mtime_ns+size.
  Survives ranger restarts. SIZES and SNAP are in-memory only.

════════════════════════════════════════════════════════════════════════════════
MAPPINGS  (rc.conf)
────────────────────────────────────────────────────────────────────────────────
  map dcf  dcsize f sort
  map dca  dcsize a sort
  map dcv  dcsize v sort filter codec=AV1
  map dcF  dcsize f sort cursor
  map dcA  dcsize a sort cursor
  map dcV  dcsize v sort filter cursor codec=AV1
  map dcu  dcsize undo

════════════════════════════════════════════════════════════════════════════════
KNOWN LIMITATIONS
────────────────────────────────────────────────────────────────────────────────
  • Hardlinks double-counted.
  • Only EXTS files codec-checked (default: .mp4).
  • UI blocks during computation; first dcv on cold cache is slow.
  • SIZES and SNAP lost on restart.
  • setlocal path restore may break on paths with spaces (ranger cmd parser).
  • fm.settings._local is private; check on ranger upgrades.
════════════════════════════════════════════════════════════════════════════════
"""

import json
import os
import stat
from concurrent.futures import ThreadPoolExecutor

from ranger.api import register_linemode
from ranger.api.commands import Command
from ranger.container.directory import Directory
from ranger.core.linemode import LinemodeBase
from ranger.ext.human_readable import human_readable

MODES = "fav"
EXTS = (".mp4",)
HIDE_EMPTY = True
CACHE = os.path.join(
    os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"),
    "ranger",
    "dcsize.json",
)
SIZES = {m: {} for m in MODES}  # mode -> {path: (nfiles, bytes)}
SPEC = (frozenset({"av1"}), frozenset())  # (wanted, unwanted) codec sets
SNAP = {}  # pwd.path -> snapshot dict

try:
    with open(CACHE) as fh:
        _FMT = json.load(fh)  # "path\0mtime_ns\0size" -> format string
except (OSError, ValueError):
    _FMT = {}
_dirty = False


# ── MediaInfo cache ───────────────────────────────────────────────────────────


def _save():
    global _dirty
    if not _dirty:
        return
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    tmp = CACHE + ".tmp"
    with open(tmp, "w") as fh:
        json.dump(_FMT, fh)
    os.replace(tmp, CACHE)
    _dirty = False


def _vfmt(p, st):
    global _dirty
    k = f"{p}\0{st.st_mtime_ns}\0{st.st_size}"
    if k not in _FMT:
        try:
            from pymediainfo import MediaInfo

            v = MediaInfo.parse(p).video_tracks
            _FMT[k] = (v[0].format or "") if v else ""
        except Exception:
            _FMT[k] = ""
        _dirty = True
    return _FMT[k]


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


# ── walk ──────────────────────────────────────────────────────────────────────


def _leaf(p, mode, st):
    if mode == "v" and not _match(_vfmt(p, st)):
        return 0, 0
    return 1, st.st_size


def _scan(path, mode, seen):
    n = size = 0
    try:
        with os.scandir(path) as it:
            for e in it:
                try:
                    link = e.is_symlink()
                    if link and mode != "a":
                        continue
                    if e.is_dir():
                        if mode == "a":
                            st = e.stat()
                            key = (st.st_dev, st.st_ino)
                            if key in seen:
                                continue
                            seen.add(key)
                        c, s = _scan(e.path, mode, seen)
                    elif link:
                        try:
                            st = e.stat()
                        except OSError:
                            st = e.stat(follow_symlinks=False)
                        c, s = 1, st.st_size
                    else:
                        if mode == "v" and not e.name.lower().endswith(EXTS):
                            continue
                        st = e.stat(follow_symlinks=False)
                        if not stat.S_ISREG(st.st_mode):
                            continue
                        c, s = _leaf(e.path, mode, st)
                except OSError:
                    continue
                n += c
                size += s
    except OSError:
        pass
    return n, size


def _tree(path, mode):
    """Top-level: symlinked dirs descended in every mode."""
    try:
        lst = os.lstat(path)
        link = stat.S_ISLNK(lst.st_mode)
        try:
            st = os.stat(path) if link else lst
        except OSError:
            return (1, lst.st_size) if mode == "a" else (0, 0)
        if stat.S_ISDIR(st.st_mode):
            return _scan(path, mode, {(st.st_dev, st.st_ino)})
        if (link and mode != "a") or not stat.S_ISREG(st.st_mode):
            return 0, 0
        if mode == "v" and not path.lower().endswith(EXTS):
            return 0, 0
        return _leaf(path, mode, st)
    except OSError:
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
    f/a: files always pass; dirs hidden if HIDE_EMPTY and count==0.
    v:   files pass only if codec matches SPEC; dirs hidden if HIDE_EMPTY and count==0.
    """

    def __init__(self, mode):
        self.mode = mode

    def __call__(self, fobj):
        if fobj.is_directory:
            if not HIDE_EMPTY:
                return True
            r = SIZES[self.mode].get(fobj.path)
            return r is None or r[0] > 0  # unknown → pass; computed empty → hide
        if self.mode == "v":
            return _get(fobj.path, "v")[0] > 0
        return True  # f/a: all files pass

    def __str__(self):
        return f"<Filter: dc{self.mode}>"

    def decompose(self):
        return [self]


def _set_filter(d, mode):
    """Update existing DcFilter in-place or append a new one."""
    for x in d.filter_stack:
        if isinstance(x, DcFilter):
            x.mode = mode
            return
    d.filter_stack.append(DcFilter(mode))


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


def _snapshot(fm, d):
    files = d.files_all or []
    sort, rev, is_local = _snap_sort(fm, d)
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


# ── command ───────────────────────────────────────────────────────────────────


class dcsize(Command):
    """:dcsize <f|a|v|undo> [sort] [filter] [cursor] [codec=…]
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
        _restore_sort(self.fm, d, sn)
        if d.files_all is not None:
            d.refilter()
        d.sort()
        self.fm.ui.redraw_main_column()

    def execute(self):
        global SPEC
        mode = self.arg(1)
        d = self.fm.thisdir

        if mode == "undo":
            return self._undo(d)
        if mode not in MODES or len(mode) != 1:
            return self.fm.notify("dcsize: mode must be f|a|v or undo", bad=True)
        if d.path not in SNAP:
            SNAP[d.path] = _snapshot(self.fm, d)

        opts, codec = set(), None
        for a in self.args[2:]:
            if a.startswith("codec="):
                codec = a[6:]
            else:
                opts.add(a)
        if mode == "v" and codec is not None:
            new = _parse_spec(codec)
            if new != SPEC:
                SPEC = new
                SIZES["v"].clear()

        name = "dc" + mode
        cursor = self.quantifier is not None or "cursor" in opts
        items = (
            ([self.fm.thisfile] if self.fm.thisfile else [])
            if cursor
            else list(d.files_all or [])
        )
        dirs = [f for f in items if f.is_directory]
        files = (
            [f for f in (d.files_all or []) if not f.is_directory]
            if "sort" in opts or "filter" in opts
            else [f for f in items if not f.is_directory]
        )

        todo = dirs + files
        if len(todo) > 1:
            with ThreadPoolExecutor() as ex:
                res = list(ex.map(lambda f: _tree(f.path, mode), todo))
        else:
            res = [_tree(f.path, mode) for f in todo]
        SIZES[mode].update({f.path: r for f, r in zip(todo, res)})
        _save()

        for f in dirs:
            f.linemode = name

        if mode in ("f", "a"):
            _set_filter(d, mode)  # always: hide empty dirs, pass files
        elif "filter" in opts:  # v with filter
            _set_filter(d, mode)  # hide empty dirs + filter files by codec
        else:  # v without filter
            _remove_filter(d)

        if d.files_all is not None:
            d.refilter()
        if "sort" in opts:
            self.fm.execute_console("set sort=" + name)
        d.sort()
        self.fm.ui.redraw_main_column()


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
            return f"({r[0]}) {s}" if fobj.is_directory else s

    Directory.sort_dict["dc" + mode] = lambda f: -SIZES[mode].get(f.path, (0, 0))[1]


for _m in MODES:
    _mk(_m)

try:
    from ranger.container.settings import ALLOWED_VALUES

    ALLOWED_VALUES["sort"].extend("dc" + m for m in MODES)
except Exception:
    pass
