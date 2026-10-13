#!/usr/bin/env python3
"""vdprobe: duration + video codec of media files; fast, with an inode-keyed cache.
Put vdprobe.py in ~/.config/ranger/plugins/. The plugins import it as ranger.plugins.vdprobe, then as plain vdprobe.

CLI   vdprobe.py [ROOT | -] [-0] > dur.txt     lines "<ms>\\t<codec>\\t<path>", video files only
        ROOT   walk it (pruning rules: "CLI scan policy" below)
        -      read paths from stdin (newline separated, or NUL with -0)
lib   from ranger.plugins import vdprobe        (or: import vdprobe)
        lookup(path, st=None) -> (res, hit)      res = (ms, codec) | None; codec "" = audio only
        info / duration / codec                  thin wrappers around lookup
        many(paths)                              dir-sized batch: ONE sql query, probe misses only
        flush()                                  persist pending rows (also runs atexit)

cache  inocache.Store; media keyed by inode, valid while (mtime_ns, size) match
       directory aggregates use a separate directory-validity store
formats  mp4/mov, mkv/webm, animated webp natively; anything else odd -> mediainfo
"""

import os
import marshal
import subprocess
import sys
import time
import threading
from struct import Struct

try:
    from plugins import inocache
except ImportError:
    import inocache

# ── config ────────────────────────────────────────────────────────────────────
VERSION = 2  # bump when parser output changes (ALL_VIDEO / WEBP_ANIM are hashed in too)
W = 4096  # one page per read; re-window only when the walk leaves it
ALL_VIDEO = (
    False  # True: walk everything, list every video track (cover-art mjpeg etc.)
)
WEBP_ANIM = "WebP"  # label for animated webp (None: ignore them)
FLUSH_EVERY = 64  # lib: rows buffered before one sqlite transaction
WORKERS = min(4, os.cpu_count() or 1)  # CLI only; the lib never forks
PAR_MIN = 2048  # CLI: fork only if at least this many files are still unprocessed ...
SLOW = 30e-6  # ... and the last 256 files cost more than this each (cold stat / real probing)
FMT = "General;%Duration%\t%Video_Format_List%\t%CompleteName%\\n"

# CLI scan policy (yours)
ANIM_ROOT = "/media/hpx/vd_ssdt5"  # under it: keep everything, incl. *-pics dirs
SKIP_EXT = (".~1~", ".~2~", ".~3~", ".part", ".gif")  # never opened
# non-native video containers worth sending to mediainfo (AVI is matched separately);
# every other unknown magic (jpeg/png/gif/text/...) is "not media" without fallback
FB_MAGIC = (b"\x30\x26\xb2\x75", b"FLV", b"OggS", b"\x00\x00\x01\xba")

BOX = Struct(">I4s").unpack_from
T4 = Struct("4x4s").unpack_from
U64 = Struct(">Q").unpack_from
V0 = Struct(">II").unpack_from
V1 = Struct(">IQ").unpack_from
LE = Struct("<4sI").unpack_from
F32 = Struct(">f").unpack_from
F64 = Struct(">d").unpack_from

TOP = {b"ftyp", b"moov", b"mdat", b"free", b"skip", b"wide"}
DESC = {b"moov", b"trak", b"mdia", b"minf", b"stbl"}
MP4V = {
    b"avc1": "AVC",
    b"avc3": "AVC",
    b"hvc1": "HEVC",
    b"hev1": "HEVC",
    b"dvh1": "HEVC",
    b"dvhe": "HEVC",
    b"vp09": "VP9",
    b"av01": "AV1",
    b"mp4v": "MPEG-4 Visual",
}
EB_DESC = {0x18538067, 0x1549A966, 0x1654AE6B, 0xAE}  # Segment Info Tracks TrackEntry
MKV = {
    b"V_VP9": "VP9",
    b"V_VP8": "VP8",
    b"V_AV1": "AV1",
    b"V_MPEG4/ISO/AVC": "AVC",
    b"V_MPEGH/ISO/HEVC": "HEVC",
}
_fadvise = getattr(os, "posix_fadvise", None)


# ── parsers ───────────────────────────────────────────────────────────────────
# each: -> (ms, codec) | None (not media / still image) | False (can't tell: ask mediainfo)
# codec "" = valid container, no video track.  b/mv = per-call buffer => thread-safe.
def _mp4(fd, b, mv, n):
    preadv = os.preadv
    base = pos = moov_end = 0
    dur = None
    codecs = []
    vid = False
    while not moov_end or pos < moov_end:
        j = pos - base
        if j < 0 or j + 40 > n:
            n = preadv(fd, (mv,), pos)
            base = pos
            j = 0
            if n < 40:
                break
        size, t = BOX(b, j)
        h = 8
        if size == 1:
            size = U64(b, j + 8)[0]
            h = 16
        elif size == 0:
            size = 1 << 62
        if size < h:
            return False
        if t in DESC:
            if t == b"moov":
                moov_end = pos + size
            elif t == b"trak":
                vid = False
            pos += h
            continue
        if t == b"mvhd":
            ts, d = V1(b, j + 28) if b[j + 8] else V0(b, j + 20)
            if not ts or not d:
                return False  # fragmented / unknown
            dur = (d * 1000 + ts // 2) // ts
        elif t == b"hdlr":
            if b[j + 16 : j + 20] == b"vide":
                vid = True
        elif t == b"stsd" and vid:
            c = MP4V.get(bytes(b[j + 20 : j + 24]))
            if c is None:
                return False
            if c not in codecs:
                codecs.append(c)
            if dur is not None and not ALL_VIDEO:
                break
        pos += size
    if dur is None:
        return False
    if codecs:
        return dur, " / ".join(codecs)
    return (dur, "") if moov_end and pos >= moov_end else False


def _ebml(fd, b, mv, n):
    preadv = os.preadv
    base = pos = 0
    dur = None
    scale = 1000000
    codecs = []
    ttype = cid = None
    tracks = False
    while True:
        j = pos - base
        if j < 0 or j + 32 > n:
            n = preadv(fd, (mv,), pos)
            base = pos
            j = 0
            if n < 16:
                break
        b0 = b[j]
        l1 = 9 - b0.bit_length()
        b1 = b[j + l1]
        if not b0 or not b1:
            return False
        l2 = 9 - b1.bit_length()
        eid = int.from_bytes(b[j : j + l1], "big")
        sz = int.from_bytes(b[j + l1 : j + l1 + l2], "big") & ((1 << 7 * l2) - 1)
        h = l1 + l2
        if eid in EB_DESC:
            if eid == 0xAE:
                ttype = cid = None
            elif eid == 0x1654AE6B:
                tracks = True
            pos += h
            continue
        if eid == 0x1F43B675:  # Cluster: headers are behind us
            break
        p = j + h
        if eid == 0x4489:
            dur = (F32 if sz == 4 else F64)(b, p)[0]
        elif eid == 0x2AD7B1:
            scale = int.from_bytes(b[p : p + sz], "big")
        elif eid == 0x83:
            ttype = b[p]
        elif eid == 0x86:
            cid = bytes(b[p : p + sz])
        if ttype == 1 and cid is not None:
            c = MKV.get(cid)
            if c is None:
                return False
            if c not in codecs:
                codecs.append(c)
            ttype = 0
            if dur is not None and not ALL_VIDEO:
                break
        pos += h + sz
    if not dur:
        return False  # no Duration (live webm)...
    ms = round(dur * scale / 1e6)
    if codecs:
        return ms, " / ".join(codecs)
    return (ms, "") if tracks else False


def _webp(fd, b, mv, n):
    if n < 30 or b[12:16] != b"VP8X" or not b[20] & 2:
        return None  # still image
    end = 8 + int.from_bytes(b[4:8], "little")
    base, pos, total = 0, 12, 0
    while pos < end:
        j = pos - base
        if j < 0 or j + 24 > n:
            n = os.preadv(fd, (mv,), pos)
            base = pos
            j = 0
            if n < 24:
                break
        t, size = LE(b, j)
        if t == b"ANMF":
            total += int.from_bytes(b[j + 20 : j + 23], "little")
        pos += 8 + size + (size & 1)
    return (total, WEBP_ANIM) if total else False


def probe_fd(fd):
    b = bytearray(W)
    mv = memoryview(b)
    n = os.preadv(fd, (mv,), 0)
    if n < 12:
        return None
    if T4(b)[0] in TOP:
        return _mp4(fd, b, mv, n)
    m = bytes(b[:4])
    if m == b"\x1aE\xdf\xa3":
        return _ebml(fd, b, mv, n)
    if m == b"RIFF":
        t = bytes(b[8:12])
        if t == b"WEBP":
            return _webp(fd, b, mv, n) if WEBP_ANIM else None
        return False if t[:3] == b"AVI" else None
    return False if m.startswith(FB_MAGIC) else None


def probe_path(path):
    try:
        fd = os.open(path, os.O_RDONLY)
    except OSError:
        return False  # unreadable now; don't cache a verdict
    try:
        if _fadvise:
            _fadvise(fd, 0, 0, os.POSIX_FADV_RANDOM)  # no readahead
        return probe_fd(fd)
    except Exception:  # OSError, struct.error, IndexError...
        return False
    finally:
        os.close(fd)


def _mediainfo_one(path):
    """exact but slow (library mode). False = couldn't ask / failed"""
    try:
        from pymediainfo import MediaInfo

        g = MediaInfo.parse(path).general_tracks
    except Exception:
        return False
    if not g:
        return None
    dur, vf = g[0].duration, g[0].video_format_list
    ms = int(round(float(dur))) if dur else 0
    if vf:
        return ms, vf
    return (ms, "") if dur else None


# ── cache ─────────────────────────────────────────────────────────────────────
_CACHE_ROOT = os.environ.get("VDPROBE_CACHE_ROOT") or "/cache/irome_db"
_STORE_ROOT = os.path.join(_CACHE_ROOT, "stores")
_media_store = inocache.Store(
    "mediainfo",
    version=VERSION + (1 if ALL_VIDEO else 0) + (1 if WEBP_ANIM else 0),
    validate="file",
    root=_STORE_ROOT,
)
_dir_store = inocache.Store("vdprobe-dirs", version=1, validate="dir", root=_STORE_ROOT)
_ABSENT = (0, -1, None)  # never matches a real file (size >= 0): "known not in db"
_mem = {}  # ino -> (mtime_ns, size, res)       process memo, validated on every use
_defer = None  # CLI: list collecting files for one batched mediainfo call
_dmem = {}  # dir ino -> (mtime_ns, obj)   directory aggregates (see dir_get)
_dstats = {}
stats = [0, 0]  # hits, misses (approximate under threads)
_pending = 0
_worker_new = None


def _put(ino, mt, sz, res, st=None):
    global _pending
    _mem[ino] = (mt, sz, res)
    if st is not None:
        if _worker_new is not None:
            _worker_new[ino] = (mt, sz, res)
        else:
            _media_store.put(st, res)
            _pending += 1
            if _pending >= FLUSH_EVERY:
                flush()


def _after_fork():
    global _pending
    _mem.clear()
    _pending = 0


os.register_at_fork(after_in_child=_after_fork)


def flush():
    global _pending
    _media_store.flush()
    _dir_store.flush()
    _pending = 0


def checkpoint():
    """Compatibility no-op; Store owns SQLite connections and checkpoints."""


# ── library API ───────────────────────────────────────────────────────────────
def lookup(path, st=None):
    """-> (res, hit). st: stat of the *followed* path if the caller already has it."""
    if st is None:
        try:
            st = os.stat(path)
        except OSError:
            return None, True
    if st.st_mode & 0o170000 != 0o100000:
        return None, True
    ino, mt, sz = st.st_ino, st.st_mtime_ns, st.st_size
    r = _mem.get(ino)
    if r is None:
        value, found = _media_store.get_with_status(st)
        r = _mem[ino] = (mt, sz, value) if found else _ABSENT
    if r is not None and r[0] == mt and r[1] == sz:
        stats[0] += 1
        return r[2], True
    stats[1] += 1
    res = probe_path(path)
    if res is False:
        if _defer is not None:
            _defer.append((path, ino, mt, sz))
            return None, False
        res = _mediainfo_one(path)
        if res is False:  # no pymediainfo / failed: remember for this session only
            _mem[ino] = (mt, sz, None)
            return None, False
    _put(ino, mt, sz, res, st)
    return res, False


def info(path, st=None):
    return lookup(path, st)[0]


def duration(path, st=None):
    """ms, or -1 if not media"""
    r = lookup(path, st)[0]
    return -1 if r is None else r[0]


def codec(path, st=None):
    """first video codec ('' if none / not media)"""
    r = lookup(path, st)[0]
    return r[1].partition(" / ")[0] if r else ""


def dir_get(ino):
    """-> (mtime_ns, obj) | None.  Opaque per-directory aggregate; the caller decides validity
    (a directory's mtime changes when entries are added/removed/renamed, NOT on in-place edits)."""
    return _dmem.get(ino)


def dir_get_stat(st):
    _dstats[st.st_ino] = st
    r = _dmem.get(st.st_ino)
    if r is None:
        obj = _dir_store.get(st)
        r = _dmem[st.st_ino] = (st.st_mtime_ns, obj) if obj is not None else None
    if r is None:
        return None
    return r if r[1] is not None else None


def dir_put(ino, mt, obj, st=None):
    """obj: anything marshal can dump (tuples/lists/dicts/str/int/None)"""
    _dmem[ino] = (mt, obj)
    st = st or _dstats.get(ino)
    if st is not None:
        _dstats[ino] = st
        _dir_store.put(st, obj)


def many(paths):
    """{path: res} for the regular files among paths. One batched query, serial probes."""
    sts = {}
    need = []
    for p in paths:
        try:
            s = os.stat(p)
        except OSError:
            continue
        if s.st_mode & 0o170000 != 0o100000:
            continue
        sts[p] = s
        if s.st_ino not in _mem:
            need.append(s)
    if need:
        for ino, row in _media_store.get_many_records(need).items():
            _mem[ino] = row
        for st in need:
            _mem.setdefault(st.st_ino, _ABSENT)
    return {p: lookup(p, s)[0] for p, s in sts.items()}


# ── CLI ───────────────────────────────────────────────────────────────────────
def _level(t, out, subs):
    """one directory: files -> out, kept subdirs -> subs"""
    d, ad, keep = t
    try:
        with os.scandir(d) as it:
            for e in it:
                try:
                    name = e.name
                    if e.is_dir(follow_symlinks=False):
                        ak = ad + "/" + name
                        k = keep or "-anim" in name or ak == ANIM_ROOT
                        if not k and (name.endswith("-pics") or "-pics-" in name):
                            continue  # whole subtree: only webp/gif
                        subs.append((e.path, ak, k))
                    elif name.endswith(SKIP_EXT) or (
                        not keep and name.endswith(".webp")
                    ):
                        continue
                    else:
                        out.append(e.path)  # files AND symlinks; stat() filters
                except OSError:
                    pass
    except OSError:
        pass


def scan(root):
    ra = os.path.realpath(root)
    stack = [(root, ra, ra == ANIM_ROOT or ra.startswith(ANIM_ROOT + "/"))]
    out = []
    while stack:
        _level(stack.pop(), out, stack)
    return out


def _parallel(paths, n):
    global _defer, _worker_new
    """fork n workers over paths; they only read _mem and probe, the parent owns sqlite"""
    library_mode = _defer is None
    library_deferred = []
    step = -(-len(paths) // n)
    kids = []
    for k in range(n):
        r, w = os.pipe()
        pid = os.fork()
        if pid == 0:
            try:
                os.close(r)
                _worker_new = {}
                if library_mode:
                    _defer = []
                chunk = paths[k * step : (k + 1) * step]
                out = [lookup(p)[0] for p in chunk]
                with os.fdopen(w, "wb") as f:
                    f.write(marshal.dumps((out, _worker_new, _defer)))
            except BaseException:
                import traceback

                traceback.print_exc()
                os._exit(1)
            os._exit(0)
        os.close(w)
        kids.append((pid, r))
    res = []
    for worker_index, (pid, r) in enumerate(kids):
        with os.fdopen(r, "rb") as f:
            data = f.read()
        if os.waitpid(pid, 0)[1] or not data:
            sys.exit("vdprobe: worker failed (traceback above); nothing written")
        out, new, dfr = marshal.loads(data)
        offset = len(res)
        res.extend(out)
        chunk = paths[worker_index * step : (worker_index + 1) * step]
        stats_by_key = {}
        for path in chunk:
            try:
                st = os.stat(path)
            except OSError:
                continue
            stats_by_key[(st.st_ino, st.st_mtime_ns, st.st_size)] = st
        for ino, (mt, sz, value) in new.items():
            st = stats_by_key.get((ino, mt, sz))
            if st is not None:
                _put(ino, mt, sz, value, st)
        if library_mode:
            library_deferred.extend(dfr)
        else:
            _defer.extend(dfr)
    if library_mode and library_deferred:
        got = dict(_mediainfo_batch(library_deferred))
        positions = {}
        for i, path in enumerate(paths):
            positions.setdefault(path, []).append(i)
        for item in library_deferred:
            path, ino, mt, sz = item
            if path not in got:
                result = _mediainfo_one(path)
                try:
                    st = os.stat(path)
                except OSError:
                    continue
                if (st.st_ino, st.st_mtime_ns, st.st_size) != (ino, mt, sz):
                    continue
                if result is False:
                    result = None
                    _mem[ino] = (mt, sz, None)
                else:
                    _put(ino, mt, sz, result, st)
                got[path] = result
        for path, result in got.items():
            for i in positions.get(path, ()):
                res[i] = result
    return res


def resolve(paths, workers=WORKERS):
    """serial while it's cheap (warm cache = ~6us/file); fork only when it stops being"""
    out = []
    n = len(paths)
    i = 0
    stat, get = os.stat, _mem.get
    while i < n:
        t = time.perf_counter()
        j = min(n, i + 256)
        for p in paths[i:j]:
            try:
                s = stat(p)
            except OSError:
                out.append(None)
                continue
            if s.st_mode & 0o170000 != 0o100000:
                out.append(None)
                continue
            r = get(s.st_ino)
            if r is not None and r[0] == s.st_mtime_ns and r[1] == s.st_size:
                out.append(r[2])
            else:
                out.append(lookup(p, s)[0])
        dt = time.perf_counter() - t
        k, i = i, j
        if workers > 1 and n - i >= PAR_MIN and dt / (j - k) > SLOW:
            out += _parallel(paths[i:], workers)
            break
    return out


def _mediainfo_batch(items):
    got = []
    for i in range(0, len(items), 200):
        part = items[i : i + 200]
        meta = {it[0]: it for it in part}
        try:
            r = subprocess.run(
                ["mediainfo", "--ParseSpeed=0", "--Inform=" + FMT, "--", *meta],
                capture_output=True,
            )
        except FileNotFoundError:
            print("vdprobe: mediainfo not found; fallback skipped", file=sys.stderr)
            break
        for l in r.stdout.splitlines():
            f = l.split(b"\t")
            it = meta.get(os.fsdecode(b"\t".join(f[2:]))) if len(f) > 2 else None
            if it is None:
                continue
            d, c = f[0].decode(), f[1].decode("utf-8", "surrogateescape")
            res = (int(d), c) if d.isdigit() else ((0, c) if c else None)
            try:
                st = os.stat(it[0])
            except OSError:
                continue
            if (st.st_ino, st.st_mtime_ns, st.st_size) != it[1:]:
                continue
            _put(it[1], it[2], it[3], res, st)
            got.append((it[0], res))
    return got


def main(argv):
    global FLUSH_EVERY, _defer
    import gc

    gc.disable()
    t0 = time.perf_counter()
    FLUSH_EVERY = 1 << 60  # one transaction at the end; workers never touch sqlite
    _media_store.flush_every = FLUSH_EVERY
    _dir_store.flush_every = FLUSH_EVERY
    args = argv[1:]
    nul = "-0" in args
    args = [a for a in args if a != "-0"]
    root = args[0] if args else "."
    sys.stdout.reconfigure(errors="surrogateescape")
    checkpoint()
    _defer = []
    if root == "-":
        paths = [p for p in sys.stdin.read().split("\0" if nul else "\n") if p]
    else:
        paths = scan(root)
    out = resolve(paths)
    ndefer = len(_defer)
    by_path = {}
    for i, p in enumerate(paths):
        by_path.setdefault(p, []).append(i)
    for p, r in _mediainfo_batch(_defer):
        for i in by_path.get(p, ()):
            out[i] = r
    lines = [f"{r[0]}\t{r[1]}\t{p}\n" for p, r in zip(paths, out) if r and r[1]]
    sys.stdout.write("".join(lines))
    sys.stdout.flush()
    flush()
    checkpoint()
    print(
        f"vdprobe: files {len(paths)}  probed {stats[1]}  mediainfo {ndefer}  "
        f"{time.perf_counter() - t0:.2f}s",
        file=sys.stderr,
    )
    os._exit(0)  # skip tearing down a few hundred thousand objects


if __name__ == "__main__":
    main(sys.argv)
