# This plugin adds the sorting algorithm called 'random'.  To enable it, type
# ":set sort=random" or create a key binding with ":map oz set sort=random"

import os

from ranger.container.directory import Directory
from ranger.container.fsobject import FileSystemObject

Directory.sort_dict["from_end"] = lambda x: x.relative_path[::-1]
Directory.sort_dict["name_len"] = lambda x: (len(x.relative_path), x.relative_path)
Directory.sort_dict["lctime"] = lambda x: -(os.lstat(x.path).st_ctime or 1)

# TODO:ALSO:(o,|o.): use rest/tail after _any_ punct symbol
# THINK: how to sort mixed dir with both "a-b" and "b" -- mix or separate
#   t = nm(x).rpartition('-');


def sort_suffix(x: FileSystemObject, s: str, longest: bool = False) -> str:
    nm = x.relative_path
    t = nm.partition(s) if longest else nm.rpartition(s)
    return t[2] if t[1] else ""


Directory.sort_dict["suffix--"] = lambda x: sort_suffix(x, "-", longest=True)
Directory.sort_dict["suffix-"] = lambda x: sort_suffix(x, "-", longest=False)
Directory.sort_dict["suffix__"] = lambda x: sort_suffix(x, "_", longest=True)
Directory.sort_dict["suffix_"] = lambda x: sort_suffix(x, "_", longest=False)

# from subprocess import check_output
# def sort_dir_size(path):
#     cmd = ('du -bs' + path).split()
#     return check_output(cmd).decode('utf-8').rstrip().split()[1]
# Directory.sort_dict['dir_size'] = sort_dir_size

# MOVE: sep plugin
# ALT:(ffproe):https://github.com/zd4y/ranger-vidlength
try:
    from functools import cache
    from typing import cast

    from pymediainfo import MediaInfo
    from ranger.api import register_linemode
    from ranger.core.linemode import DEFAULT_LINEMODE, LinemodeBase
except Exception:
    pass
else:
    # BET:PERF: read durations from /cache/irome_db
    @cache
    def get_duration_mediainfo(path: str) -> int:
        """
        Parses media file duration in milliseconds.
        Returns: -1 on error, 1 if empty/zero, otherwise duration in ms.
        """
        try:
            # ALT: $ find ... -print0 | xargs -0r mediainfo --Inform="General;%Duration%"$'\t'"%CompleteName%\n" -- >> withdur.txt
            media_info = cast(MediaInfo, MediaInfo.parse(path))
            for track in media_info.tracks:  # pyright: ignore[reportUnknownVariableType, reportUnknownMemberType]
                if track.track_type == "General" and track.duration:  # pyright: ignore[reportUnknownMemberType]
                    # MediaInfo returns duration in milliseconds (as a string or int)
                    duration = int(track.duration)  # pyright: ignore[reportUnknownArgumentType, reportUnknownMemberType]
                    return duration if duration > 0 else 1
        except (ValueError, TypeError, AttributeError, Exception):
            return -1  # corrupt files or missing data
        return -1

    Directory.sort_dict["duration"] = lambda x: get_duration_mediainfo(x.path)

    @register_linemode
    class DurationLinemode(LinemodeBase):
        name = "duration"

        def filetitle(self, f: FileSystemObject, metadata: object) -> str:
            return f.relative_path

        def infostring(self, f: FileSystemObject, metadata: object) -> str:
            if not f.is_file or not (f.video or f.audio):
                return self._get_default_infostring(f, metadata)

            ms = get_duration_mediainfo(f.path)
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
            return (f"{m}:" if m else "") + f"{s:02d}.{ms:03d}"

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
