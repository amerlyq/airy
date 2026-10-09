import os
from stat import S_ISREG

from ranger.container.directory import Directory
from ranger.container.fsobject import FileSystemObject

# ALT:(ffproe):https://github.com/zd4y/ranger-vidlength
try:
    from ranger.api import register_linemode
    from ranger.core.filter_stack import stack_filter
    from ranger.core.linemode import DEFAULT_LINEMODE, LinemodeBase
    from ranger.core.shared import FileManagerAware
except Exception:
    pass
else:
    # outside the try on purpose: a missing vdprobe must be a visible error, not a silent no-op
    try:
        # ranger imports plugins as `plugins.<name>`
        from plugins import vdprobe
    except ImportError:
        import vdprobe  # fallback: vdprobe.py somewhere on PYTHONPATH

    def _st(f: FileSystemObject):
        """ranger already stat'ed the file: reuse it, but not a symlink's lstat"""
        st = getattr(f, "stat", None)
        return st if st is not None and S_ISREG(st.st_mode) else None

    def get_duration_mediainfo(path: str, st=None) -> int:
        """
        Duration in milliseconds (vdprobe: native parse + inode-keyed cache).
        Returns: -1 if not media, 1 if zero, otherwise duration in ms.
        """
        ms = vdprobe.duration(path, st)
        return ms if ms > 0 or ms < 0 else 1

    Directory.sort_dict["duration"] = lambda x: get_duration_mediainfo(x.path, _st(x))

    @register_linemode
    class DurationLinemode(LinemodeBase):
        name = "duration"

        def filetitle(self, f: FileSystemObject, metadata: object) -> str:
            return f.relative_path

        def infostring(self, f: FileSystemObject, metadata: object) -> str:
            ## FAIL: mimetype is empty for .mp4_*
            # if not f.is_file or not (f.video or f.audio):
            if not (f.is_file and (f.video or f.audio or ".mp4" in f.basename)):
                return self._get_default_infostring(f, metadata)

            ms = get_duration_mediainfo(f.path, _st(f))
            if ms <= 0:
                return self._get_default_infostring(f, metadata)
                # if ms < 0:
                #     return "ERR"
                # if ms == 0:
                #     return "ZERO"
            if ms <= 1:
                return "WTF"
            s, ms = divmod(ms, 1000)
            m, s = divmod(s, 60)
            sz = f"({f.size / 1024 / 1024:.1f}M) "
            return sz + (f"{m}:" if m else "") + f"{s:02d}.{ms:03d}"

        def _get_default_infostring(self, f: FileSystemObject, metadata: object) -> str:
            # OR: return DefaultLinemode().infostring(f, metadata)

            # 1. Fetch default mode string (usually "filename" or whatever DEFAULT_LINEMODE is)
            default_mode_name = DEFAULT_LINEMODE

            # Avoid recursion if DEFAULT_LINEMODE happens to be set to "duration"
            if default_mode_name == self.name:
                default_mode_name = "filename"

            # 2. Retrieve instance from file's linemode dictionary
            fallback_linemode = f.linemode_dict.get(default_mode_name)
            if fallback_linemode:
                return fallback_linemode.infostring(f, metadata)

            return ""

    @stack_filter("duration")
    class DurationFilter(FileManagerAware):
        def __init__(self, arg):
            self.tol = int(arg) if arg else 500
            self._cache = {}  # dirpath -> (len(files_all), set(paired paths))

        def _scan(self, files):
            res = vdprobe.many([x.path for x in files if not x.is_directory])
            ms = [(max(r[0], 1), p) for p, r in res.items() if r]
            ms.sort()
            out = set()
            for i, (v, p) in enumerate(ms):
                if (
                    i
                    and v - ms[i - 1][0] <= self.tol
                    or i + 1 < len(ms)
                    and ms[i + 1][0] - v <= self.tol
                ):
                    out.add(p)
            return out

        def __call__(self, f):
            if f.is_directory:
                return True
            d = os.path.dirname(f.path)
            files = self.fm.get_directory(d).files_all or []
            hit = self._cache.get(d)
            if hit is None or hit[0] != len(files):  # rescan if listing changed
                hit = self._cache[d] = (len(files), self._scan(files))
            return f.path in hit[1]

        def __str__(self):
            return f"<Filter: duration pairs ±{self.tol}ms>"
