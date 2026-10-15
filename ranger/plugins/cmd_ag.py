"""cmd_ag: `:ag` -- ripgrep front-end (shell pager / nvim quickfix / nvim grouped / filter current dir).

## USAGE: :ag [-v|-g|-l|-p|-f|-r|-u] [-Q] [-w] PATTERN      (-r = narrow cwd to files with matches)
## MAPS (rc.conf): `\\aa` `\\a;` `\\a.` + loop-generated `ag{f,l,v,g,p,u}` aliases (left in rc.conf, short)
## ARCH: _choose() -> _aug_*() builds (cmd, flags) -> execute() runs; `-r` goes through _catch()+_filter() instead
## WHY: class-level `patterns` = shared history across calls, so <Tab> and the empty-arg call reuse the last one
## DEBUG: :eval fm.commands['ag'].patterns
## CONFLICT: treefilter.py `:tfilter_rg` does the same as `ag -r` but tree-preserving/async/nestable
##   -> ALT: drop `-r` (+ _catch, _filter) once tfilter_rg is trusted. Kept for now.
## CONFLICT: `filter_stack clear` / `;c` do NOT touch `ag -r` (it sets temporary_filter, not the stack)
"""

from __future__ import annotations

import os
import re
from collections.abc import Sequence
from re import Pattern
from typing import ClassVar, TypeAlias, cast

from ranger.api.commands import Command
from ranger.ext.shell_escape import shell_quote

try:
    from plugins.base_util import FilterableDirectory
except ModuleNotFoundError:
    from base_util import FilterableDirectory

CommandLine: TypeAlias = str | list[str]
CommandSpec: TypeAlias = tuple[CommandLine, str]


class ag(Command):
    """:ag 'regex'

    Looks for a string in all marked paths or current dir
    """

    editor: ClassVar[str] = os.getenv("EDITOR") or "vim"
    acmd: ClassVar[str] = (
        "rg --pcre2 --smart-case --color always --hidden"  # --search-zip
    )
    qarg: ClassVar[Pattern[str]] = re.compile(r"""^(".*"|'.*')$""")
    patterns: ClassVar[list[str]] = []
    # THINK:USE: set_clipboard on each direct ':ag' search? So I could find in vim easily

    def _sel(self) -> list[str]:
        d = self.fm.thisdir
        if d.marked_items:
            return [f.relative_path for f in d.marked_items]
        # WARN: permanently hidden files like .* are searched anyways
        #   << BUG: files skipped in .agignore are grep'ed being added on cmdline
        if d.temporary_filter and d.files_all and (len(d.files_all) != len(d.files)):
            return [f.relative_path for f in d.files]
        return []

    def _arg(self, i: int = 1) -> str:
        if self.rest(i):
            ag.patterns.append(self.rest(i))
        return ag.patterns[-1] if ag.patterns else ""

    def _quot(self, patt: str) -> str:
        return patt if ag.qarg.match(patt) else shell_quote(patt)

    def _bare(self, patt: str) -> str:
        return patt[1:-1] if ag.qarg.match(patt) else patt

    def _aug_vim(self, iarg: int, comm: str = "Ag") -> CommandSpec:
        if self.arg(iarg) == "-Q":
            self.shift()
            comm = "sil AgSet def.e.literal 1|" + comm
        # patt = self._quot(self._arg(iarg))
        patt = self._arg(iarg)  # No need to quote in new ag.vim
        # FIXME:(add support)  'AgPaths' + self._sel()
        cmd = f"{comm} {patt}"
        cmdl = [ag.editor, "-c", cmd, "-c", "only"]
        return (cmdl, "")

    def _aug_nvr(self, iarg: int, group: bool | None = None) -> CommandSpec:
        cmdl = ["rg", "--pcre2", "--smart-case", "--hidden"]
        if group:
            cmdl += ["--column"]
        else:
            cmdl += ["--vimgrep"]

        if iarg == 1:
            import shlex

            cmdl += shlex.split(self.rest(iarg))
        else:
            # NOTE: only allowed switches
            opt = self.arg(iarg)
            while opt in ["-Q", "-w"]:
                self.shift()
                if opt == "-Q":
                    cmdl.append("--fixed-strings")
                elif opt == "-w":
                    cmdl.append("--word-regexp")
                opt = self.arg(iarg)
            # TODO: save -Q/-w into ag.patterns =NEED rewrite plugin to join _aug*()
            patt = self._quot(self._bare(self._arg(iarg)))
            cmdl.append(patt)

        if group:
            cmdl += [
                "|",
                ag.editor,
                "-",
                '+"setl noro ma bt=nofile"',
                '+"set cole=0 fdl=1|setf ag_grp"',
            ]
        else:
            # BUG:(bdelete 1): we close wrong buffer for ranger-filechooser.vim (because it reads into last buffer)
            cmdl += [
                "|sort|",
                ag.editor,
                '+"setl noro ma bt=nofile|cbuffer|copen"',
                "-",
            ]
        return (" ".join(cmdl), "")

    def _aug_sh(self, iarg: int, flags: Sequence[str] = ()) -> CommandSpec:
        cmdl = ag.acmd.split() + list(flags)
        if iarg == 1:
            import shlex

            cmdl += shlex.split(self.rest(iarg))
        else:
            # NOTE: only allowed switches
            opt = self.arg(iarg)
            while opt in ["-Q", "-w"]:
                self.shift()
                if opt == "-Q":
                    cmdl.append("--fixed-strings")
                elif opt == "-w":
                    cmdl.append("--word-regexp")
                opt = self.arg(iarg)
            # TODO: save -Q/-w into ag.patterns =NEED rewrite plugin to join _aug*()
            patt = self._bare(self._arg(iarg))  # THINK? use shlex.split() also/instead
            cmdl.append(patt)
        if "-g" not in flags:
            cmdl += self._sel()
        return (cmdl, "-p")

    def _choose(self) -> CommandSpec:
        if self.arg(1) == "-v":
            return self._aug_nvr(2, False)
        elif self.arg(1) == "-g":
            return self._aug_nvr(2, True)
        elif self.arg(1) == "-l":
            return self._aug_sh(2, ["--files-with-matches", "--count"])
        elif self.arg(1) == "-p":  # paths
            return self._aug_sh(2, ["-g"])
        elif self.arg(1) == "-f":
            return self._aug_sh(2)
        elif self.arg(1) == "-r":
            return self._aug_sh(2, ["--files-with-matches"])
        elif self.arg(1) == "-u":
            return self._aug_sh(2, ["--unrestricted", "--follow"])
        else:
            return self._aug_sh(1)

    def _catch(self, cmd: CommandLine) -> list[str] | None:
        from subprocess import CalledProcessError, check_output

        try:
            out = check_output(cmd)
        except CalledProcessError:
            return None
        else:
            return out[:-1].decode("utf-8").splitlines()

    # DEV
    # NOTE: regex becomes very big for big dirs
    # BAD: flat ignores 'filter' for nested dirs
    def _filter(
        self, lst: Sequence[str] | None, thisdir: FilterableDirectory | None = None
    ) -> None:
        # filter /^rel_dir/ on lst
        # get leftmost path elements
        # make regex '^' + '|'.join(re.escape(nm)) + '$'
        if not lst:
            return
        if thisdir is None:
            thisdir = cast(FilterableDirectory | None, self.fm.thisdir)
        if thisdir is None:
            return
        file_with_matches = r"^(?:" + "|".join(map(re.escape, lst)) + r")$"
        thisdir.temporary_filter = re.compile(file_with_matches)
        thisdir.refilter()

        if thisdir.files_all is None:
            return
        for f in thisdir.files_all:
            if f.is_directory:
                # DEV: each time filter-out one level of files from lst
                self._filter(lst, cast(FilterableDirectory, cast(object, f)))

    def execute(self) -> None:
        cmd, flags = self._choose()
        # self.fm.notify(cmd)
        # TODO:ENH: cmd may be [..] -- no need to shell_escape
        if self.arg(1) != "-r":
            self.fm.execute_command(cmd, flags=flags)
        else:
            self._filter(self._catch(cmd))

    def tab(self, tabnum: int) -> list[str]:  # pyright: ignore[reportIncompatibleMethodOverride]
        # BAD:(:ag <prev_patt>) when input alias ':agv' and then <Tab>
        #   <= EXPL: aliases expanded before parsing cmdline
        cmd = self.arg(0)
        flg = self.arg(1)
        if flg[0] == "-" and flg[1] in "flvgprw":
            cmd += " " + flg
        return [f"{cmd} {p}" for p in reversed(ag.patterns)]
