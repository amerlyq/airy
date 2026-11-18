"""Keep named video clips beside their source while preserving Ranger's selected sort.

Toggle with `:group_clips` (bind it to a key if desired). Ranger exposes one sort-key
function, so grouping is applied as a stable secondary sort after its normal sort; duration
view uses clip grouping first and duration within each original/clip cluster.
"""

from __future__ import annotations

import os
import re

from ranger.container.directory import Directory

_TOKEN = r"(?:\d+m\d+s\d+|v\d+|prev\d+)"
_CLIP_SUFFIX = re.compile(_TOKEN + r"(?:_" + _TOKEN + r")*$")
_GROUPED_DIRS: set[str] = set()


def _clip_key(file):
    """Return (source stem, is clip, stable name) for `<source>_<clip tokens>` names."""
    stem = os.path.splitext(file.basename)[0]
    match = _CLIP_SUFFIX.search(stem)
    if match:
        return stem[: match.start()].rstrip("_").casefold(), 1, stem.casefold()
    return stem.casefold(), 0, stem.casefold()


def grouping_enabled(path: str) -> bool:
    return path in _GROUPED_DIRS


def clip_source(file):
    source, is_clip, _ = _clip_key(file)
    return source if is_clip else None


def _make_sort(original):
    def sort(self):
        original(self)
        if self.path not in _GROUPED_DIRS or not self.files_all:
            return

        # Keep Ranger's order for group anchors and within each original/clip subgroup.
        ordered = list(enumerate(self.files_all))
        source_groups = {}
        for index, file in ordered:
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
            for _, file, _ in sorted(
                ordered,
                key=lambda row: (
                    anchors[_clip_key(row[1])[0]],
                    _clip_key(row[1])[1],
                    row[0],
                ),
            )
        ]

    return sort


try:
    import rhooks
except ImportError:
    from plugins import rhooks
rhooks.patch(Directory, "sort", _make_sort)


try:
    from ranger.api.commands import Command
except ImportError:
    pass
else:
    class group_clips(Command):
        """:group_clips toggles grouping clips after their source, preserving active sort."""

        def execute(self):
            path = self.fm.thisdir.path
            if path in _GROUPED_DIRS:
                _GROUPED_DIRS.remove(path)
                enabled = False
            else:
                _GROUPED_DIRS.add(path)
                enabled = True
            self.fm.thisdir.sort()
            self.fm.thisdir.refilter()
            self.fm.ui.redraw_main_column()
            self.fm.notify(f"Clip grouping {'on' if enabled else 'off'}")

