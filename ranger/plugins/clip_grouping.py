"""Keep named video clips beside their source while preserving Ranger's selected sort.

Toggle with `:group_clips` (bind it to a key if desired). Ranger exposes one sort-key
function, so grouping is applied as a stable secondary sort after its normal sort; duration
view uses clip grouping first and duration within each original/clip cluster.
"""

from __future__ import annotations

import os
import re

from ranger.container.directory import Directory
from ranger.gui.widgets.browsercolumn import BrowserColumn

_TOKEN = r"(?:\d+m\d+s\d+|v\d+|prev\d+)"
_CLIP_SUFFIX = re.compile(_TOKEN + r"(?:_" + _TOKEN + r")*$")
GROUP_DECOR_MODE = True  # Master toggle used by `ov`; enabled by default.
GROUP_CLIPS_ENABLED = True
DECORATE_CLIP_NAMES = True  # `oV` can override decoration independently.
_DURATION_SAVED_MODES: dict[str, tuple[bool, bool, bool]] = {}


def enter_duration_view(path: str) -> None:
    """Save the pre-duration clip mode once, then disable grouping and decoration."""
    global GROUP_DECOR_MODE, GROUP_CLIPS_ENABLED, DECORATE_CLIP_NAMES
    _DURATION_SAVED_MODES.setdefault(
        path, (GROUP_DECOR_MODE, GROUP_CLIPS_ENABLED, DECORATE_CLIP_NAMES)
    )
    GROUP_DECOR_MODE = GROUP_CLIPS_ENABLED = DECORATE_CLIP_NAMES = False


def leave_duration_view(path: str) -> None:
    """Restore exact clip flags saved when this directory entered duration view."""
    global GROUP_DECOR_MODE, GROUP_CLIPS_ENABLED, DECORATE_CLIP_NAMES
    saved = _DURATION_SAVED_MODES.pop(path, None)
    if saved is not None:
        GROUP_DECOR_MODE, GROUP_CLIPS_ENABLED, DECORATE_CLIP_NAMES = saved


def _clip_key(file):
    """Return (source stem, is clip, stable name) for `<source>_<clip tokens>` names."""
    stem = os.path.splitext(file.basename)[0]
    match = _CLIP_SUFFIX.search(stem)
    if match:
        return stem[: match.start()].rstrip("_").casefold(), 1, stem.casefold()
    return stem.casefold(), 0, stem.casefold()


def grouping_enabled(_path: str) -> bool:
    return GROUP_CLIPS_ENABLED


def clip_source(file):
    source, is_clip, _ = _clip_key(file)
    return source if is_clip else None


def _make_sort(original):
    def sort(self):
        original(self)
        if not self.files_all:
            return

        if not GROUP_CLIPS_ENABLED:
            if DECORATE_CLIP_NAMES:
                for file in self.files_all:
                    file.display_data.clear()
            return

        # Keep Ranger's order for group anchors and within each original/clip subgroup.
        ordered = list(enumerate(self.files_all))
        source_groups = {}
        for index, file in ordered:
            if file.is_directory:
                continue
            source, is_clip, _ = _clip_key(file)
            source_groups.setdefault(source, []).append((index, file, is_clip))
        anchors = {
            source: min(
                (index for index, _, is_clip in members if not is_clip),
                default=min(index for index, _, _ in members),
            )
            for source, members in source_groups.items()
        }
        self.files_all[:] = [
            file
            for _, file in sorted(
                ordered,
                key=lambda row: (
                    row[0] if row[1].is_directory else anchors[_clip_key(row[1])[0]],
                    0 if row[1].is_directory else _clip_key(row[1])[1],
                    row[0],
                ),
            )
        ]
        for file in self.files_all:
            file.display_data.clear()
        # Ranger refilters before this wrapper reorders files_all; refilter again so visible
        # files follow the grouped order after every sort setting change.
        self.refilter()

    return sort


def _make_text_display(original):
    def draw_text(self, text, space):
        # BrowserColumn formats every linemode title through this method, so decoration stays
        # visual only: file paths, macros, and the active linemode retain the real filename.
        if DECORATE_CLIP_NAMES:
            icon, separator, title = text.partition(" ")
            codepoint = ord(icon[0]) if len(icon) == 1 else 0
            has_devicon = separator and len(icon) == 1 and (
                0xE000 <= codepoint <= 0xF8FF
                or 0xF0000 <= codepoint <= 0xFFFFD
                or 0x100000 <= codepoint <= 0x10FFFD
            )
            candidate = title if has_devicon else text
            name = os.path.basename(candidate)
            stem = os.path.splitext(name)[0]
            match = _CLIP_SUFFIX.search(stem)
            if match:
                source = stem[: match.start()].rstrip("_").casefold()
                prefix = "├ "
                if self.target is not None:
                    clips = [
                        file.basename
                        for file in (self.target.files or [])
                        if clip_source(file) == source
                    ]
                    originals = [
                        file for file in (self.target.files_all or [])
                        if not file.is_directory
                        and clip_source(file) is None
                        and os.path.splitext(file.basename)[0].casefold() == source
                    ]
                    if not originals:
                        if len(clips) == 1:
                            prefix = "· "
                        elif clips and clips[0] == name:
                            prefix = "┌ "
                        elif clips and clips[-1] == name:
                            prefix = "└ "
                    elif clips and clips[-1] == name:
                        prefix = "└ "
                # Replace an existing devicon when present; two-column prefix aligns the title.
                text = prefix + title if separator and candidate == title else prefix + text
        return original(self, text, space)

    return draw_text


try:
    import rhooks
except ImportError:
    from plugins import rhooks
rhooks.patch(Directory, "sort", _make_sort)
rhooks.patch(BrowserColumn, "_draw_text_display", _make_text_display)

try:
    import ranger

    if ranger.fm is not None and ranger.fm.thisdir is not None:
        ranger.fm.thisdir.sort()
except Exception:  # startup may not have selected a directory yet
    pass


try:
    from ranger.api.commands import Command
except ImportError:
    pass
else:
    class group_clips(Command):
        """:group_clips toggles grouping clips after their source, preserving active sort."""

        def execute(self):
            global GROUP_CLIPS_ENABLED
            GROUP_CLIPS_ENABLED = not GROUP_CLIPS_ENABLED
            enabled = GROUP_CLIPS_ENABLED
            self.fm.thisdir.sort()
            self.fm.thisdir.refilter()
            for file in self.fm.thisdir.files_all or []:
                file.display_data.clear()
            self.fm.ui.redraw_main_column()
            self.fm.notify(f"Clip grouping {'on' if enabled else 'off'}")


    class clip_sorting(Command):
        """:clip_sorting [on|off|toggle] [group] [decorate] [group+decorate] [sort=<name>]

        Grouping and decoration are global mode flags; an optional active sort stays independent.
        """

        def execute(self):
            global DECORATE_CLIP_NAMES

            args = list(self.args[1:])
            operation = args.pop(0) if args and args[0] in ("on", "off", "toggle") else "toggle"
            features = set(args)
            allowed = {"group", "decorate", "group+decorate"}
            sort_args = [arg for arg in features if arg.startswith("sort=")]
            unknown = features - allowed - set(sort_args)
            if unknown or len(sort_args) > 1:
                return self.fm.notify(
                    "Usage: clip_sorting [on|off|toggle] [group] [decorate] [group+decorate] [sort=<name>]",
                    bad=True,
                )
            for arg in sort_args:
                sort = arg.partition("=")[2]
                if sort not in Directory.sort_dict:
                    return self.fm.notify(f"Unknown sort: {sort}", bad=True)

            fm = self.fm
            global GROUP_CLIPS_ENABLED, GROUP_DECOR_MODE
            if "group+decorate" in features:
                GROUP_DECOR_MODE = (
                    operation == "on"
                    or (operation == "toggle" and not GROUP_DECOR_MODE)
                )
                GROUP_CLIPS_ENABLED = GROUP_DECOR_MODE
                DECORATE_CLIP_NAMES = GROUP_DECOR_MODE
            if "group" in features:
                GROUP_CLIPS_ENABLED = (
                    operation == "on"
                    or (operation == "toggle" and not GROUP_CLIPS_ENABLED)
                )
            if "decorate" in features:
                DECORATE_CLIP_NAMES = (
                    operation == "on"
                    or (operation == "toggle" and not DECORATE_CLIP_NAMES)
                )
            for arg in sort_args:
                sort = arg.partition("=")[2]
                fm.execute_console(f"setlocal sort={sort}")
            fm.thisdir.sort()
            fm.thisdir.refilter()
            if features & {"group", "decorate", "group+decorate"}:
                for file in fm.thisdir.files_all or []:
                    file.display_data.clear()
            fm.ui.redraw_main_column()

