from os import path as fs

from ranger.api.commands import Command
from ranger.container.history import History
from ranger.core.fm import FM


### DEBUG
# :eval fm.thistab.history.maxlen
# :eval len(fm.thistab.history.history)
# :eval fm.thistab.history.__dict__
# :eval fm.notify("\n".join(map(str, fm.thistab.history.history)) + f"\n@{fm.thistab.history.index}")
# :display_log
# :eval fm.thistab.history.unique
# :eval setattr(fm.thistab.history, 'unique', False) → test live
# :eval h = fm.thistab.history; h.history = [h.current()]; h.index = 0
#   drop only the back part, keep forward: h.history = h.history[h.index:]; h.index = 0
#   drop only the forward part: del h.history[h.index + 1:]
#   per-tab → other tabs keep their history
class history_clear(Command):
    def execute(self):
        h = self.fm.thistab.history
        cur = h.current()
        h.history = [cur]
        h.index = 0


# Cause: probably History.add dedup + truncate, not the cap.
# add does del _history[_index+1:], then remove(item) for an existing equal entry, then append.
# → revisiting the same few dirs (symlink dir, plugin target, siblings) moves them to the end instead of adding steps
# → the list collapses to the set of distinct dirs, in last-visit order
# → history_go -1 at index 0 is a no-op → "stuck"
#
# Step 3 in cd_symlink1 is probably a no-op or broken:
# → attrs are _history / _index (verify with :eval fm.thistab.history.__dict__); history.index / history.history probably don't exist (the latter just creates a new unused attribute)
# → enter_dir → add already truncates the forward part
#
# → every cd / select_file / enter_dir(history=True) goes through add, so symlink + plugin jumps are covered
# → if __dict__ shows different attr names in your version, adjust
# Related, only if relevant:
#   History.modify(unique=True) has its own dedup (used by some callers; probably not in this path)
#   consecutive-only dedup → ping-pong A↔B between plugin jumps still fills the 100 slots
#   new tabs copy history via History.__init__/rebuild → the patch applies there tookkkk
#
# def add(self, item):
#     del self._history[self._index + 1 :]
#     if self._history and self._history[-1] == item:
#         return
#     if len(self._history) >= max(self.maxlen, 1):
#         del self._history[0]
#     self._history.append(item)
#     self._index = len(self._history) - 1
#
#
# History.add = add


class move_parent_nohist(Command):
    def execute(self):
        fm = self.fm
        parent = fm.thistab.at_level(-1)
        if parent is None:
            return
        n = int(self.arg(1)) * (self.quantifier or 1)
        i = max(0, min(parent.pointer + n, len(parent.files) - 1))
        fm.change_mode("normal")
        fm.thistab.enter_dir(parent.files[i], history=False)


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

        # 3. Truncate forward history if we moved back with 'H'
        tab = fm.thistab
        if tab is None:
            fm.notify("No active tab!", bad=True)
            return
        history = tab.history
        if history and history.index < len(history) - 1:
            # history.container = history.container[: history.index + 1]
            # history._list = history._list[: history.index + 1]
            # if hasattr(history, "history"):
            history.history = history.history[: history.index + 1]

        # 4. Handle existing target (Directory or File)
        if fs.isdir(target_path):
            fm.cd(str(target_path))
            return

        if fs.isfile(target_path):
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
