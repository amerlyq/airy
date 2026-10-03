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

from ranger.container.history import History
from ranger.core.tab import Tab


def _is_step(frame):
    if not frame.f_code.co_filename.endswith("core/actions.py"):
        return False
    name = frame.f_code.co_name
    if name == "move":
        return True
    if name == "move_parent":
        return abs(frame.f_locals.get("n", 0)) == 1
    return False


## ALG:
# A → D: add(A), add(D) gives [A, D]
# D → S1: add(D) is skipped (it's last), add(S1) gives [A, D, S1]
# S1 → S2: [A, D, S1, S2]
# S2 → A: [A, D, S1, S2, A], so [5/5]
# history-back steps S2, S1, D, A, one entry per jump
def _add(self, item):
    h = self.history
    # ALT:BUG: dedup messes history chain when chained symlinks walk you back to starting dir
    # if item in h:
    #     h.remove(item)
    # h.append(item)
    if not h or h[-1] != item:
        h.append(item)
    self.index = len(h) - 1
    if self.maxlen and len(h) > self.maxlen:
        del h[0]
        self.index -= 1


History.add = _add

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
        self.history.add(old)
        self.history.add(new)
    return ret


Tab.enter_dir = enter_dir


import os
from os import path as fs
from typing import cast

from ranger.core.fm import FM
from ranger.gui.widgets.titlebar import TitleBar


class cd_symlink1(Command):
    """
    Follows a symlink exactly 1 level deep, maintaining a strict history chain.
    Handles broken symlinks by navigating to the closest parent directory.
    Trims future history when branching off via <H> + <cl>.
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

        # # 3. Truncate forward history if we moved back with 'H'
        # tab = fm.thistab
        # if tab is None:
        #     fm.notify("No active tab!", bad=True)
        #     return
        # history = tab.history
        # if history and history.index < len(history) - 1:
        #     # history.container = history.container[: history.index + 1]
        #     # history._list = history._list[: history.index + 1]
        #     # if hasattr(history, "history"):
        #     history.history = history.history[: history.index + 1]

        # 4. Handle existing target (Directory or File)
        if fs.isdir(target_path):
            fm.cd(str(target_path))
            return

        if fs.isfile(target_path) or fs.islink(target_path):
            parent_dir: str = fs.dirname(target_path)
            fm.cd(str(parent_dir))
            if fm.thisdir:
                fm.thisdir.move_to_obj(str(target_path))
            return

        # 5. Handle broken symlink -> find nearest existing directory
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
