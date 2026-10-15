"""cmd_actualee: `:actualee [-FLAG]` -- run ~/.local/bin/actualee on cursor file + rotated dir listing.

## ARCH: dir listing is written (rotated to start at cursor) to base_util.tmpfile("buffer") and passed via `-l`
## DEBUG: cat $XDG_RUNTIME_DIR/ranger/buffer
## MAPS: <CR>
"""
from __future__ import annotations

from typing import ClassVar, cast

from ranger.api.commands import Command

try:
    from plugins.base_util import CompletionResult, tmpfile
except ModuleNotFoundError:
    from base_util import CompletionResult, tmpfile


class actualee(Command):
    FLST: ClassVar[str] = tmpfile("buffer")
    """:actualee
    Use '~/.local/bin/actually' to apply secondary action to file/list
    """

    def execute(self) -> None:
        cur = self.fm.thisfile
        if cur.is_file and "x" in cur.get_permission_string():
            self.fm.execute_command(cur.path)
            return

        cmd = ["actualee"]

        if self.arg(1) and self.arg(1)[0] == "-":
            cmd += [self.arg(1)]
            self.shift()
        else:
            cmd += ["-e"]

        s = [f.path for f in self.fm.thisdir.files]
        index = s.index(self.fm.thisfile.path)
        with open(actualee.FLST, "w") as f:
            f.write("\n".join(s[index:] + s[:index]))
            cmd += ["-l"]

        if self.fm.thisfile.is_file:
            cmd += [self.fm.thisfile.path]
            cmd += [actualee.FLST]
            # if 'x' in file.get_permission_string():
            self.fm.execute_command(cmd)
        else:
            self.fm.move(right=1)

    def tab(self, tabnum: int) -> CompletionResult:  # pyright: ignore[reportIncompatibleMethodOverride]
        return cast(CompletionResult, self._tab_directory_content())
