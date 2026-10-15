"""cmd_cli: overrides for console, edit, touch, mkdir, mkdircd (:md), reload_rc.

## WHY override: `console -pN` (cursor position), quantifier = history jump; `edit` w/o args edits cursor file
## ARCH: later registration wins => these shadow ranger.config.commands builtins of the same name
## MAPS: <F12> reload_rc | alias md -> mkdircd (rc.conf) | e/E/ge/ee use edit
## NOTE: reload_rc re-sources rc.conf only; plugins and hook_init are NOT re-run
"""

from __future__ import annotations

from os import makedirs
from os.path import dirname, expanduser, join, lexists
from typing import cast

from ranger.api.commands import Command

try:
    from plugins import pasteflow
except ImportError:
    import pasteflow

try:
    from plugins.base_util import CompletionResult
except ModuleNotFoundError:
    from base_util import CompletionResult


class console(Command):
    """:console <command>

    Open the console with the given command.
    """

    def execute(self) -> None:
        pos = None
        if self.arg(1)[0:2] == "-p":
            try:
                pos = int(self.arg(1)[2:])
                self.shift()
            except ValueError:
                pos = None

        command = self.rest(1)
        # if pos is None or int(pos) > len(command):
        #     command += " "
        self.fm.open_console(command, position=pos)
        if not command and self.quantifier is not None:
            self.fm.ui.console.history_move(-self.quantifier)


class edit(Command):
    """:edit <filename>

    Opens the specified file in vim
    """

    def execute(self) -> None:
        if not self.arg(1):
            self.fm.edit_file(self.fm.thisfile.path)
        # BAD: don't work
        elif self.rest(1) in [".", " "]:
            self.fm.edit_file("")
        else:
            self.fm.edit_file(self.rest(1))

    def tab(self, tabnum: int) -> CompletionResult:  # pyright: ignore[reportIncompatibleMethodOverride]
        return cast(CompletionResult, self._tab_directory_content())


class mkdir(Command):
    """:mkdir <dirname>

    Create directory and move cursor to it.
    """

    def execute(self) -> None:
        fm = self.fm
        path = join(fm.thisdir.path, expanduser(self.rest(1)))

        def create(_fm) -> None:
            if not lexists(path):
                makedirs(path)
            else:
                fm.notify("file/directory exists!", bad=True)

        pasteflow.run_custom(fm, create)

    def tab(self, tabnum: int) -> CompletionResult:  # pyright: ignore[reportIncompatibleMethodOverride]
        return cast(CompletionResult, self._tab_directory_content())


class touch(Command):
    """:touch <fname>

    Create file and move cursor to it.
    """

    def execute(self) -> None:
        fm = self.fm
        path = join(fm.thisdir.path, expanduser(self.rest(1)))
        parent = dirname(path)

        def create(_fm) -> None:
            if lexists(path):
                fm.notify("file/directory exists!", bad=True)
                return
            if not lexists(parent):
                makedirs(parent)
            with open(path, "a", encoding="utf-8"):
                pass

        pasteflow.run_custom(fm, create)

    def tab(self, tabnum: int) -> CompletionResult:  # pyright: ignore[reportIncompatibleMethodOverride]
        return cast(CompletionResult, self._tab_directory_content())


class mkdircd(Command):
    """:md <dirname> OR :mkdircd <dirname>"""

    def execute(self) -> None:
        nm = self.rest(1)
        self.fm.mkdir(nm)
        # BAD: cursor isn't moved to new dir
        self.fm.cd(nm)
        # self.fm.select_file(fs.join(self.fm.thisdir.path, nm))
        # self.fm.move(right=1)

    def tab(self, tabnum: int) -> CompletionResult:  # pyright: ignore[reportIncompatibleMethodOverride]
        return cast(CompletionResult, self._tab_directory_content())


# %ONELINE: alias reload_rc chain eval fm.source(fm.confpath('rc.conf')); eval fm.rifle.reload_config(); eval fm.notify('Reload rc.conf', 1)
class reload_rc(Command):
    """:reload_rc -- re-source rc.conf and rifle.conf"""

    def execute(self) -> None:
        fm = self.fm
        fm.source(fm.confpath("rc.conf"))
        fm.rifle.reload_config()
        fm.notify("Reload rc.conf", 1)
