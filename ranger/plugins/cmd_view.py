"""cmd_view: view-state commands: flat_inode, unfilter, toggle_preview_images, sort_reset, view_duration.

## DEPS: view_duration needs vddur_sort_linemode.py (sort "duration", linemode "duration", filter "duration")
## CONFLICT(treefilter.py): `filter_stack clear` (used by view_duration off, `;c`) does NOT drop tfilter layers:
##   treefilter's refilter() re-adds them from its own stack. Use :tfilter_undo [-a].
## CONFLICT: `unfilter` clears Directory.filter only (probably not temporary_filter set by `ag -r`)
## DEBUG: flat_inode still notifies inode_type_filter on every call -- remove when stable
"""

from __future__ import annotations

import re
from typing import cast

from ranger.api.commands import Command
from ranger.container.directory import Directory

from plugins.rutil import FilterableDirectory

# HACK:FIXME: wide icons (OR: narrow font)
# os.environ["RANGER_DEVICONS_SEPARATOR"]="  "

# to ensure ranger visual indicators show tags correctly for realpath files, override get_tags in
# ~/.config/ranger/commands.py (or your overriding class):
# def get_tags(self, path):
#     """Resolve symlink and retrieve tags for the real path."""
#     real_path = os.path.realpath(path)
#     return self.fm.tags.get(real_path)


class flat_inode(Command):
    """:flat_inode [-t] [<[fdl]>] [<level>]

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

        if toggle and q == self.fm.thisdir.flat and self.fm.thisdir.inode_type_filter:
            t, q = "", 0

        self.fm.notify(self.fm.thisdir.inode_type_filter)
        cmd = "chain filter_inode_type " + t + "; flat " + str(q)
        self.fm.execute_console(cmd)

    def tab(self, tabnum: int) -> list[str]:  # pyright: ignore[reportIncompatibleMethodOverride]
        return ["flat_inode " + t for t in "dfl"]


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
        fm.thisdir.sort()


### ALT:FAIL:
## map od eval fm.thisdir.settings['sort'] = 'duration'; fm.thisdir.settings['sort_reverse'] = True; fm.execute_console(f"default_linemode path={fm.thisdir.path} duration")
## map on eval fm.execute_console(f"setlocal path={fm.thisdir.path} sort=natural"); fm.execute_console(f"setlocal path={fm.thisdir.path} sort_reverse=False"); fm.execute_console(f"default_linemode path={fm.thisdir.path} None")
## map on eval fm.thisdir.settings['sort'] = 'natural'; fm.thisdir.settings['sort_reverse'] = False; fm.set_option_from_string('default_linemode', 'None', localpath=fm.thisdir.path); fm.thisdir.unload(); fm.thisdir.load_content()
## map on eval fm.thisdir.settings['sort'] = 'natural'; fm.thisdir.settings['sort_reverse'] = False; from ranger.container.fsobject import FileSystemObject; FileSystemObject.linemode_policies.pop(('path', fm.thisdir.path), None); fm.thisdir.unload(); fm.thisdir.load_content()
# %ONELINE:
# map od chain setlocal sort=duration;  setlocal sort_reverse=True; eval fm.execute_console(f"default_linemode path={fm.thisdir.path} duration"); linemode duration; filter_stack add duration
# map on chain setlocal sort=natural;  setlocal sort_reverse=False; eval fm.execute_console(f"default_linemode path={fm.thisdir.path} devicons"); filter_stack clear; linemode devicons
class view_duration(Command):
    """:view_duration [off]

    on : sort by duration (reverse), linemode duration for cwd, filter duration pairs
    off: back to natural sort + devicons, clear filter_stack
    """

    def execute(self) -> None:
        fm = self.fm
        path = fm.thisdir.path
        if self.arg(1) == "off":
            seq = [
                "setlocal sort=natural",
                "setlocal sort_reverse=False",
                f"default_linemode path={path} devicons",  # FIXME: path is a regex, not escaped (as before)
                "filter_stack clear",
                "linemode devicons",
            ]
        else:
            if "duration" not in Directory.sort_dict:
                return fm.notify(
                    "view_duration: vddur_sort_linemode not loaded", bad=True
                )
            seq = [
                "setlocal sort=duration",
                "setlocal sort_reverse=True",
                f"default_linemode path={path} duration",
                "linemode duration",
                "filter_stack add duration",
            ]
        for c in seq:
            fm.execute_console(c)
