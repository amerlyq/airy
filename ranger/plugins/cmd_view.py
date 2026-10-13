"""cmd_view: view-state commands: flat_inode, unfilter, toggle_preview_images, sort_reset.

## CONFLICT(treefilter.py): `filter_stack clear` (used by view_duration off, `;c`) does NOT drop tfilter layers:
##   treefilter's refilter() re-adds them from its own stack. Use :tfilter_undo [-a].
## CONFLICT: `unfilter` clears Directory.filter only (probably not temporary_filter set by `ag -r`)
## DEBUG: flat_inode still notifies inode_type_filter on every call -- remove when stable
"""

from __future__ import annotations

import os
import re
import threading
from typing import cast

from plugins.rutil import FilterableDirectory
from ranger.api.commands import Command
from ranger.container import directory as ranger_directory


class _InodeTypeFilter:
    def __init__(self, types: str) -> None:
        self.types = types

    def __call__(self, obj) -> bool:
        return (
            ("d" in self.types and obj.is_directory)
            or ("f" in self.types and obj.is_file and not obj.is_link)
            or ("l" in self.types and obj.is_link)
        )

    def __str__(self) -> str:
        return "inode type: " + self.types


_flat_context = threading.local()
_walklevel = getattr(ranger_directory.walklevel, "_flat_inode_original", ranger_directory.walklevel)
_load_bit_by_bit = getattr(
    ranger_directory.Directory.load_bit_by_bit,
    "_flat_inode_original",
    ranger_directory.Directory.load_bit_by_bit,
)


def _filtered_walklevel(path, level):
    context = getattr(_flat_context, "value", None)
    if context is not None and path != context[0].path:
        context = None
    prune = context is not None and context[3]
    if prune:
        context[3] = False
    for root, dirs, files in _walklevel(path, level):
        if prune:
            directory, visible_entries, hidden, _ = context
            if root == directory.path and visible_entries is not None:
                dirs[:] = [
                    name for name in dirs
                    if os.path.join(root, name) in visible_entries
                ]
                files[:] = [
                    name for name in files
                    if os.path.join(root, name) in visible_entries
                ]
            if hidden is not None:
                dirs[:] = [
                    name for name in dirs
                    if not hidden.search(name)
                ]
        yield root, dirs, files


def _filtered_load_bit_by_bit(self):
    generator = _load_bit_by_bit(self)
    if not self.flat or not getattr(self, "_flat_inode_active", False):
        yield from generator
        return
    visible_entries = getattr(self, "_flat_inode_entries", None)
    hidden = None
    if not self.settings.show_hidden and self.settings.hidden_filter:
        hidden = re.compile(self.settings.hidden_filter)
    try:
        item = next(generator)
    except StopIteration:
        return
    yield item

    _flat_context.value = [self, visible_entries, hidden, True]
    try:
        item = next(generator)
    except StopIteration:
        return
    finally:
        _flat_context.value = None
    yield item
    yield from generator


ranger_directory.walklevel = _filtered_walklevel
ranger_directory.Directory.load_bit_by_bit = _filtered_load_bit_by_bit
_filtered_walklevel._flat_inode_original = _walklevel
_filtered_load_bit_by_bit._flat_inode_original = _load_bit_by_bit

# HACK:FIXME: wide icons (OR: narrow font)
# os.environ["RANGER_DEVICONS_SEPARATOR"]="  "

# to ensure ranger visual indicators show tags correctly for realpath files, override get_tags in
# ~/.config/ranger/commands.py (or your overriding class):
# def get_tags(self, path):
#     """Resolve symlink and retrieve tags for the real path."""
#     real_path = os.path.realpath(path)
#     return self.fm.tags.get(real_path)


class flat_inode(Command):
    """:flat_inode [-t] [<[dflu]>] [<level>]

    Set/Toggle inode flattened view
        <quantifier> augments missing argument: level or [fdl] bitmask
    """

    def q_inode_mask(self, q: int | None) -> str:
        return (
            ""
            if q is None
            else ("f" if q & 0x1 else "")
            + ("d" if q & 0x2 else "")
            + ("l" if q & 0x4 else "")
        )

    def q_flat(self, q: int | None) -> int:
        return -1 if self.quantifier is None else self.quantifier

    def execute(self) -> None:
        toggle = self.arg(1) == "-t"
        if toggle:
            self.shift()

        if re.match("^-?\\d+$", self.arg(1)):
            t = self.arg(2) or self.q_inode_mask(self.quantifier)
            q = self.arg(1)
        else:
            t = self.arg(1)
            q = self.arg(2) or self.q_flat(self.quantifier)

        try:
            q = int(q)
        except (TypeError, ValueError):
            return self.fm.notify("flat_inode: level must be an integer", bad=True)
        if "u" in t:
            t, q = "", 0

        directory = self.fm.thisdir
        if directory.files_all is None or directory.files is None:
            previous_flat = directory.flat
            if directory.loading:
                directory.unload()
            directory.flat = 0
            try:
                directory.load_content(schedule=False)
            finally:
                directory.flat = previous_flat
            if directory.files_all is None or directory.files is None:
                return self.fm.notify("flat_inode: directory contents unavailable", bad=True)
        directory.refilter()
        prefiltered_entries = getattr(directory, "_flat_inode_entries", None)
        if prefiltered_entries is None:
            prefiltered_entries = {item.path for item in directory.files}
        current = next((f for f in directory.filter_stack if isinstance(f, _InodeTypeFilter)), None)
        if toggle and q == directory.flat and current:
            t, q = "", 0

        directory.filter_stack[:] = [f for f in directory.filter_stack if not isinstance(f, _InodeTypeFilter)]
        if t:
            directory.filter_stack.append(_InodeTypeFilter(t))
        directory.inode_type_filter = None
        directory._flat_inode_active = q != 0
        directory._flat_inode_entries = prefiltered_entries if q != 0 else None
        directory.refilter()
        self.fm.execute_console("flat " + str(q))

    def tab(self, tabnum: int) -> list[str]:  # pyright: ignore[reportIncompatibleMethodOverride]
        return ["flat_inode " + t for t in "dflu"]


class unfilter(Command):
    def unfilter(self, d: FilterableDirectory) -> None:
        # BAD: d.files_all == None ???
        # [self.unfilter(f) for f in d.files_all if f.is_directory]
        d.filter = None
        d.refilter()
        # for f in d.files_all:
        #     if f.is_directory:
        #         self.unfilter(f)

    def execute(self) -> None:
        self.unfilter(cast(FilterableDirectory, self.fm.thisdir))


# %ONELINE: map zi    chain set preview_images!; eval cmd("map i tag_toggle" if fm.settings.preview_images else "map i display_file")
class toggle_preview_images(Command):
    """:toggle_preview_images -- toggle + rebind `i` (tag_toggle when images preview is on, else display_file)"""

    def execute(self) -> None:
        fm = self.fm
        fm.execute_console("set preview_images!")
        fm.execute_console(
            "map i tag_toggle" if fm.settings.preview_images else "map i display_file"
        )


# HACK: removes the exact-path setlocal sort=... entry and immediately re-sorts using the global set sort=... value.
# %ONELINE: map o0 eval s=fm.settings._localsettings.get(re.escape(fm.thisdir.path) + '$', {}); s.pop('sort', None); s.pop('sort_reverse', None); fm.thisdir.sort()
class sort_reset(Command):
    """:sort_reset -- drop directory-local `sort`/`sort_reverse` overrides of cwd"""

    def execute(self) -> None:
        fm = self.fm
        s = fm.settings._localsettings.get(re.escape(fm.thisdir.path) + "$", {})
        s.pop("sort", None)
        s.pop("sort_reverse", None)
        # "filter_stack clear; setlocal sort=natural; setlocal sort_reverse=False"
        # FIXME: path is a regex, not escaped (as before)
        fm.execute_console(
            f"chain default_linemode path={fm.thisdir.path} devicons; linemode devicons"
        )
        fm.thisdir.refilter()
        fm.thisdir.sort()
        fm.ui.redraw_main_column()
