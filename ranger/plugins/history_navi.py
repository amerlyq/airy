from ranger.api.commands import Command


### DEBUG: history per-tab → other tabs keep their history
# :eval fm.thistab.history.maxlen
# :eval len(fm.thistab.history.history)
# :eval fm.thistab.history.__dict__
# :eval fm.notify("\n".join(map(str, fm.thistab.history.history)) + f"\n@{fm.thistab.history.index}")
# :display_log
# :eval fm.thistab.history.unique
# :eval setattr(fm.thistab.history, 'unique', False)
# :eval h = fm.thistab.history; h.history = [h.current()]; h.index = 0
#   OR: drop only the back part, keep forward: h.history = h.history[h.index:]; h.index = 0
#   OR: drop only the forward part: del h.history[h.index + 1:]
class history_clear(Command):
    def execute(self):
        h = self.fm.thistab.history
        cur = h.current()
        h.history = [cur]
        h.index = 0


# map J     move_parent_nohist 1
# map K     move_parent_nohist -1
# class move_parent_nohist(Command):
#     def execute(self):
#         fm = self.fm
#         parent = fm.thistab.at_level(-1)
#         if parent is None:
#             return
#         n = int(self.arg(1)) * (self.quantifier or 1)
#         i = max(0, min(parent.pointer + n, len(parent.files) - 1))
#         fm.change_mode("normal")
#         fm.thistab.enter_dir(parent.files[i], history=False)


import sys

from ranger.core.actions import Actions
from ranger.core.tab import Tab

## What happens on a jump that is not a plain step (e.g. <cl>) when you are NOT at the end of
## history (you went back with <H> before):
##   "truncate"  browser-like: forward entries are dropped, the new place follows current
##               [1/35] + jump → [2/2]
##   "insert"    the new place goes right after current, forward entries stay behind it
##               [1/35] + jump → [2/36]   (keeps accidentally forked visits reachable)
## Retracing the same jump (<cl> <H> <cl> <H> …) never grows history in either mode.
FORK = "truncate"


import os

import ranger

_RANGER_DIR = os.path.dirname(os.path.abspath(ranger.__file__)) + os.sep


def _is_step(frame):
    """Is enter_dir() reached from ranger's own move() / move_parent() (a plain h/l/j/k step)?

    Frames of other plugins that wrap Tab.enter_dir sit in between: they are skipped, the first
    frame inside the ranger package decides. (Wrapper order is therefore irrelevant.)
    """
    for _ in range(8):
        if frame is None:
            return False
        if os.path.abspath(frame.f_code.co_filename).startswith(_RANGER_DIR):
            break
        frame = frame.f_back
    else:
        return False
    if not frame.f_code.co_filename.endswith("core/actions.py"):
        return False
    name = frame.f_code.co_name
    if name == "move":
        return True
    if name == "move_parent":
        return abs(frame.f_locals.get("n", 0)) == 1
    return False


## ALG: one jump records old and new, relative to the CURRENT index (not to the list end!):
# A → D: [A, D] @D
# D → S1: current is already D; [A, D, S1]
# S1 → S2: [A, D, S1, S2]
# S2 → A: [A, D, S1, S2, A], so [5/5]
# history-back steps S2, S1, D, A, one entry per jump
# <H> from D to A: [A, D, S1, S2, A] @A is not touched by add; jumping A → D again:
#   next entry already is D → just move index forward, nothing is appended
# ALT:BUG: dedup messes history chain when chained symlinks walk you back to starting dir
def _visit(h, item):
    """Make `item` the current entry of tab history `h`: stay, retrace forward, or fork."""
    items = h.history
    if not items:
        items.append(item)
        h.index = 0
        return
    h.index = max(0, min(h.index, len(items) - 1))
    if items[h.index] == item:
        return
    nxt = h.index + 1
    if nxt < len(items) and items[nxt] == item:
        h.index = nxt
        return
    if FORK == "truncate":
        del items[nxt:]
    items.insert(nxt, item)
    h.index = nxt
    if h.maxlen and len(items) > h.maxlen:
        del items[0]
        h.index -= 1


_enter_dir = Tab.enter_dir


def enter_dir(self, path, history=True):
    step = _is_step(sys._getframe(1))
    old = self.thisdir
    ret = _enter_dir(self, path, history=False)
    new = self.thisdir
    record = history and old and new and old.path != new.path and not step
    ## DEBUG:
    # --- tracedump: comment out when done ---
    # __import__("logging").getLogger(__name__).warning(
    #     "enter_dir %s -> %s step=%s record=%s\n%s",
    #     getattr(old, "path", None),
    #     getattr(new, "path", None),
    #     step,
    #     bool(record),
    #     "".join(__import__("traceback").format_stack(limit=6)[:-1]),
    # )
    # ----------------------------------------
    if record:
        _visit(self.history, old)
        _visit(self.history, new)
    return ret


Tab.enter_dir = enter_dir


def _sync_parent_cursor(tab):
    """Match normal directory navigation after history restores a directory directly."""
    if tab.thisdir:
        tab.assign_cursor_positions_for_subdirs()


_history_go = Actions.history_go


def history_go(self, relative):
    ret = _history_go(self, relative)
    _sync_parent_cursor(self.thistab)
    return ret


Actions.history_go = history_go


import os
from os import path as fs
from typing import cast

from ranger.core.fm import FM
from ranger.gui.widgets.titlebar import TitleBar


class cd_symlink1(Command):
    """
    Follows a symlink exactly 1 level deep, maintaining a strict history chain.
    Handles broken symlinks by navigating to the closest parent directory.
    Branching off after <H> + <cl> follows FORK (truncate forward history by default).
    """

    def execute(self) -> None:
        fm = cast(FM, self.fm)
        thisfile = fm.thisfile

        if not thisfile or not thisfile.is_link:
            fm.notify("Not a symlink!", bad=True)
            return

        origin_dir: str = fm.thisdir.path
        origin_file: str = thisfile.path

        # 1. Read 1-level link target
        try:
            link_target: str = os.readlink(origin_file)
        except OSError as e:
            fm.notify(f"Cannot read link: {e}", bad=True)
            return

        # 2. Resolve target path
        target_path: str = (
            fs.normpath(link_target)
            if fs.isabs(link_target)
            else fs.normpath(fs.join(origin_dir, link_target))
        )

        # 3. Handle existing target (Directory or File); history is handled in enter_dir()
        if fs.isdir(target_path):
            fm.cd(str(target_path))
            return

        if fs.isfile(target_path) or fs.islink(target_path):
            parent_dir: str = fs.dirname(target_path)
            fm.cd(str(parent_dir))
            if fm.thisdir:
                fm.thisdir.move_to_obj(str(target_path))
            return

        # 4. Handle broken symlink -> find nearest existing directory
        target_dir: str = (
            target_path if fs.isdir(target_path) else fs.dirname(target_path)
        )
        while target_dir and not fs.exists(target_dir):
            parent: str = fs.dirname(target_dir)
            if parent == target_dir:
                break
            target_dir = parent

        if fs.exists(target_dir):
            fm.notify(
                f"Link target missing! Navigating to closest dir: {target_dir}",
                bad=True,
            )
            fm.cd(str(target_dir))
        else:
            fm.notify("Link target and parent directories do not exist!", bad=True)


def _hist(self):
    h = self.fm.thistab.history
    return f"[{len(h) and h.index + 1}/{len(h)}]"


_tb_left = TitleBar._get_left_part


def tb_left(self, bar):
    _tb_left(self, bar)
    n = len(bar.left)
    bar.left.add(_hist(self), "history", fixedsize=True)
    bar.left.add_space()
    bar.left[:] = bar.left[n:] + bar.left[:n]


TitleBar._get_left_part = tb_left

## ALT: prepend to statusbar below
# from ranger.gui.widgets.statusbar import StatusBar
# _sb_left = StatusBar._get_left_part
#
# def sb_left(self, bar):
#     _sb_left(self, bar)
#     n = len(bar.left)
#     bar.left.add(_hist(self), "history")
#     bar.left.add_space()
#     bar.left[:] = bar.left[n:] + bar.left[:n]
# StatusBar._get_left_part = sb_left
#
## statusbar: append (right edge)
# _sb_right = StatusBar._get_right_part
# def sb_right(self, bar):
#     _sb_right(self, bar)
#     n = len(bar.right)
#     bar.right.add(_hist(self), "history")
#     bar.right.add_space()
#     bar.right[:] = bar.right[n:] + bar.right[:n]
# StatusBar._get_right_part = sb_right
