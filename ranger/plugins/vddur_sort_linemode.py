import os
from stat import S_ISREG

from ranger.container.directory import Directory
from ranger.container.fsobject import FileSystemObject

# ALT:(ffproe):https://github.com/zd4y/ranger-vidlength
try:
    from ranger.api import register_linemode
    from ranger.api.commands import Command
    from ranger.core.filter_stack import stack_filter
    from ranger.core.linemode import DEFAULT_LINEMODE, LinemodeBase
    from ranger.core.shared import FileManagerAware
    import ranger.gui.context as gui_context
    import ranger.gui.widgets.browsercolumn as browsercolumn
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

    def duration_groups(files, tolerance=500):
        """Group media entries whose adjacent durations differ by at most tolerance."""
        by_path = {f.path: f for f in files if not f.is_directory}
        durations = vdprobe.many(list(by_path))
        rows = sorted(
            (max(result[0], 1), path, by_path[path])
            for path, result in durations.items()
            if result and path in by_path
        )
        groups = []
        for ms, _, file in rows:
            if not groups or ms - groups[-1][-1][0] > tolerance:
                groups.append([])
            groups[-1].append((ms, file))
        return [[file for _, file in group] for group in groups]

    ### ALT:FAIL:
    ## map od eval fm.thisdir.settings['sort'] = 'duration'; fm.thisdir.settings['sort_reverse'] = True; fm.execute_console(f"default_linemode path={fm.thisdir.path} duration")
    ## map on eval fm.execute_console(f"setlocal path={fm.thisdir.path} sort=natural"); fm.execute_console(f"setlocal path={fm.thisdir.path} sort_reverse=False"); fm.execute_console(f"default_linemode path={fm.thisdir.path} None")
    ## map on eval fm.thisdir.settings['sort'] = 'natural'; fm.thisdir.settings['sort_reverse'] = False; fm.set_option_from_string('default_linemode', 'None', localpath=fm.thisdir.path); fm.thisdir.unload(); fm.thisdir.load_content()
    ## map on eval fm.thisdir.settings['sort'] = 'natural'; fm.thisdir.settings['sort_reverse'] = False; from ranger.container.fsobject import FileSystemObject; FileSystemObject.linemode_policies.pop(('path', fm.thisdir.path), None); fm.thisdir.unload(); fm.thisdir.load_content()
    # %ONELINE:
    # map od chain setlocal sort=duration;  setlocal sort_reverse=True; eval fm.execute_console(f"default_linemode path={fm.thisdir.path} duration"); linemode duration; filter_stack add duration
    # map oD chain setlocal sort=natural;  setlocal sort_reverse=False; eval fm.execute_console(f"default_linemode path={fm.thisdir.path} devicons"); filter_stack clear; linemode devicons
    class view_duration(Command):
        """:view_duration [on|off|toggle] [grayout]

        on : sort by duration (reverse), use duration linemode, filter duration pairs
        grayout: keep unpaired files visible in dim gray
        off: back to natural sort + devicons, clear filter_stack
        """

        def execute(self):
            fm = self.fm
            mode = self.arg(1) or "toggle"
            grayout = len(self.args) > 2 and self.arg(2) == "grayout"
            if (
                mode not in ("on", "off", "toggle")
                or len(self.args) > 3
                or (len(self.args) > 2 and not grayout)
            ):
                return fm.notify("Usage: view_duration [on|off|toggle] [grayout]", bad=True)
            if mode == "toggle":
                active = fm.thisdir.settings.sort == "duration" or any(
                    isinstance(item, DurationFilter) for item in fm.thisdir.filter_stack
                )
                mode = "off" if active else "on"
            path = fm.thisdir.path
            if mode == "off":
                commands = (
                    "filter_stack clear",
                    "setlocal sort=natural",
                    "setlocal sort_reverse=False",
                    f"default_linemode path={path} devicons",  # FIXME: path is a regex, not escaped (as before)
                    "linemode devicons",
                )
            else:
                commands = (
                    "setlocal sort=duration",
                    "setlocal sort_reverse=True",
                    f"default_linemode path={path} duration",
                    "linemode duration",
                )
            for command in commands:
                fm.execute_console(command)
            if mode == "on":
                fm.thisdir.filter_stack[:] = [
                    item for item in fm.thisdir.filter_stack
                    if not isinstance(item, DurationFilter)
                ]
                fm.thisdir.filter_stack.append(DurationFilter("", grayout=grayout))
            fm.thisdir.refilter()
            fm.thisdir.sort()
            fm.ui.redraw_main_column()

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
        def __init__(self, arg, grayout=False):
            self.tol = int(arg) if arg else 500
            self.grayout = grayout
            self._cache = {}  # dirpath -> (len(files_all), set(paired paths))

        def _scan(self, files):
            return {
                f.path
                for group in duration_groups(files, self.tol)
                if len(group) > 1
                for f in group
            }

        def paired(self, directory, f):
            d = directory.path
            files = self.fm.get_directory(d).files_all or []
            hit = self._cache.get(d)
            if hit is None or hit[0] != len(files):  # rescan if listing changed
                hit = self._cache[d] = (len(files), self._scan(files))
            return f.path in hit[1]

        def __call__(self, f):
            if f.is_directory:
                return True
            directory = self.fm.get_directory(os.path.dirname(f.path))
            return self.paired(directory, f) or self.grayout

        def __str__(self):
            suffix = "; unpaired dim" if self.grayout else ""
            return f"<Filter: duration pairs ±{self.tol}ms{suffix}>"

    if "duration_unpaired" not in gui_context.CONTEXT_KEYS:
        gui_context.CONTEXT_KEYS.append("duration_unpaired")
    setattr(gui_context.Context, "duration_unpaired", False)
    _old_hook_before_drawing = getattr(
        browsercolumn.hook_before_drawing,
        "_duration_original",
        browsercolumn.hook_before_drawing,
    )

    def _duration_color_hook(fsobj, colors):
        fsobj, colors = _old_hook_before_drawing(fsobj, colors)
        if fsobj.is_file:
            directory = FileManagerAware.fm.thisdir
            if os.path.dirname(fsobj.path) == directory.path:
                for item in directory.filter_stack:
                    if (
                        isinstance(item, DurationFilter)
                        and item.grayout
                        and not item.paired(directory, fsobj)
                    ):
                        colors.append("duration_unpaired")
                        break
        return fsobj, colors

    browsercolumn.hook_before_drawing = _duration_color_hook
    _duration_color_hook._duration_original = _old_hook_before_drawing
