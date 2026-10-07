import json
import os
import stat
from concurrent.futures import ThreadPoolExecutor

from ranger.api import register_linemode
from ranger.api.commands import Command
from ranger.container.directory import Directory
from ranger.core.linemode import LinemodeBase
from ranger.ext.human_readable import human_readable

try:
    from ranger.core.filter_stack import stack_filter
except ImportError:
    stack_filter = lambda name: lambda cls: cls

MODES = "fav"  # f: no symlinks, a: with symlinks, v: codec-matching video
EXTS = (".mp4",)
HIDE_EMPTY = True  # codec filter also hides dirs whose computed (v) count/size is 0
CACHE = os.path.join(
    os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"),
    "ranger",
    "dcsize.json",
)
SIZES = {m: {} for m in MODES}  # mode -> {path: (nfiles, bytes)}
SPEC = (frozenset({"av1"}), frozenset())  # (wanted, unwanted) codecs for mode v
SNAP = {}  # pwd -> state before the first dc* run there

try:
    with open(CACHE) as fh:
        _FMT = json.load(fh)  # "path\0mtime_ns\0size" -> first video track format
except (OSError, ValueError):
    _FMT = {}
_dirty = False


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


def _parse(s):
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
                    if e.is_dir():  # follows links
                        if mode == "a":  # loop guard
                            st = e.stat()
                            key = (st.st_dev, st.st_ino)
                            if key in seen:
                                continue
                            seen.add(key)
                        c, s = _scan(e.path, mode, seen)
                    elif link:  # mode a: file or broken link
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
    """Top-level entry: a symlink to a dir is a dir (descended in every mode)."""
    try:
        lst = os.lstat(path)
        link = stat.S_ISLNK(lst.st_mode)
        try:
            st = os.stat(path) if link else lst
        except OSError:  # broken link
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


@stack_filter("codec")
class CodecFilter:
    """Files pass if they match SPEC. Dirs pass unless computed as empty (HIDE_EMPTY)."""

    def __init__(self, args=None):
        pass

    def __call__(self, fobj):
        if fobj.is_directory:
            r = SIZES["v"].get(fobj.path)
            return not (HIDE_EMPTY and r is not None and (r[0] == 0 or r[1] == 0))
        return _get(fobj.path, "v")[0] > 0

    def __str__(self):
        return "<Filter: codec>"

    def decompose(self):
        return [self]


def _unfilter(d):
    for x in [x for x in d.filter_stack if isinstance(x, CodecFilter)]:
        d.filter_stack.remove(x)


def _snapshot(fm, d):
    files = d.files_all or []
    return dict(
        sort=fm.settings.sort,
        rev=fm.settings.sort_reverse,
        filt=list(d.filter_stack),
        lm={f.path: f.linemode for f in files},
        sizes={m: {f.path: SIZES[m].get(f.path) for f in files} for m in MODES},
    )


class dcsize(Command):
    """:dcsize <f|a|v|u> [sort] [filter] [cursor] [codec=a,b | codec=!a,!b]
    u: undo everything dc* did in this pwd. A count prefix implies cursor.
    codec/filter apply to mode v only."""

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
        self.fm.execute_console("set sort=%s" % sn["sort"])
        self.fm.execute_console("set sort_reverse=%s" % sn["rev"])
        if d.files_all is not None:
            d.refilter()
        d.sort()
        self.fm.ui.redraw_main_column()

    def execute(self):
        global SPEC
        mode = self.arg(1)
        d = self.fm.thisdir
        if mode == "u":
            return self._undo(d)
        if mode not in MODES or len(mode) != 1:
            return self.fm.notify("dcsize: mode must be f|a|v|u", bad=True)
        if d.path not in SNAP:
            SNAP[d.path] = _snapshot(self.fm, d)

        opts, codec = set(), None
        for a in self.args[2:]:
            if a.startswith("codec="):
                codec = a[6:]
            else:
                opts.add(a)
        if mode == "v" and codec is not None:
            new = _parse(codec)
            if new != SPEC:
                SPEC = new
                SIZES["v"].clear()

        name = "dc" + mode
        if self.quantifier is not None or "cursor" in opts:
            items = [self.fm.thisfile] if self.fm.thisfile else []
        else:
            items = list(d.files_all or [])
        dirs = [f for f in items if f.is_directory]
        if (
            "sort" in opts or "filter" in opts
        ):  # sort/filter need data for all cwd files
            files = [f for f in (d.files_all or []) if not f.is_directory]
        else:
            files = [f for f in items if not f.is_directory]

        todo = dirs + files
        if len(todo) > 1:
            with ThreadPoolExecutor() as ex:
                res = list(ex.map(lambda f: _tree(f.path, mode), todo))
        else:
            res = [_tree(f.path, mode) for f in todo]
        SIZES[mode].update({f.path: r for f, r in zip(todo, res)})
        _save()

        for f in dirs:  # linemode: cwd dirs only
            f.linemode = name

        if mode == "v":
            if "filter" in opts and not any(
                isinstance(x, CodecFilter) for x in d.filter_stack
            ):
                d.filter_stack.append(CodecFilter())
        else:
            _unfilter(d)
        if d.files_all is not None:
            d.refilter()

        if "sort" in opts:
            self.fm.execute_console("set sort=" + name)
        d.sort()
        self.fm.ui.redraw_main_column()


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
