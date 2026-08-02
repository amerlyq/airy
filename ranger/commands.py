from __future__ import annotations

import os
import re
from collections.abc import Callable, Iterable, Sequence
from os import path as fs
from re import Pattern
from typing import ClassVar, Protocol, TypeAlias, cast

from ranger.api.commands import Command
from ranger.core.fm import FM
from ranger.ext.shell_escape import shell_quote

CommandLine: TypeAlias = str | list[str]
CommandSpec: TypeAlias = tuple[CommandLine, str]
CompletionResult: TypeAlias = str | Iterable[str] | None


class DirectoryEntry(Protocol):
    """The filesystem-object surface needed by recursive filtering."""

    is_directory: bool


class FilterableDirectory(Protocol):
    """The directory surface used by ``ag._filter`` and ``unfilter``."""

    filter: object | None
    temporary_filter: Pattern[str] | None
    files_all: Sequence[DirectoryEntry] | None

    def refilter(self) -> None: ...

# HACK:FIXME: wide icons (OR: narrow font)
# os.environ["RANGER_DEVICONS_SEPARATOR"]="  "


# to ensure ranger visual indicators show tags correctly for realpath files, override get_tags in
# ~/.config/ranger/commands.py (or your overriding class):
# def get_tags(self, path):
#     """Resolve symlink and retrieve tags for the real path."""
#     real_path = os.path.realpath(path)
#     return self.fm.tags.get(real_path)


# NOTE: jump to next day only at 7:00AM
def today_date(delta: int = 7) -> str:
    import datetime

    return (
        datetime.datetime.now(datetime.timezone.utc).astimezone()
        - datetime.timedelta(hours=delta)
    ).strftime(
        "%Y-%m-%d"
    )


# BAD: ranger crash on exit if '--choosedir' path was deleted by 3rd party
def tmpfile(nm: str) -> str:
    ge = os.getenv
    tmp = ge(
        "RANGER_TMPDIR",
        # ALT: fs.join(ge("TMPDIR", fs.join("/tmp", ge("USER", ""), "ranger"))),
        fs.join(ge("XDG_RUNTIME_DIR", "/tmp"), "ranger"),
    )
    if not fs.isdir(tmp):
        os.mkdir(tmp)
    return fs.join(tmp, nm)


class ag(Command):
    """:ag 'regex'

    Looks for a string in all marked paths or current dir
    """

    editor: ClassVar[str] = os.getenv("EDITOR") or "vim"
    acmd: ClassVar[str] = "rg --pcre2 --smart-case --color always --hidden"  # --search-zip
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


class doc(Command):
    lst: ClassVar[dict[str, str]] = {
        "a": "ARCH",
        "b": "DEBUG",
        "c": "CHGLOG",
        "d": "DEV",
        "e": "EXAMPLES",
        "f": "FUTURE",
        "g": "LEGEND",
        "h": "HACK",
        "i": "INFO",
        "k": "WKLOG",  # OR: WORKLOG
        "l": "LIOR",
        "m": "MAINT",
        "n": "NOTE",
        "o": "comment",
        "r": "README",
        "s": "SYNERGY",
        "t": "TODO",
        "u": "USAGE",
        "w": "HOWTO",
        "z": "SEIZE",
        ".": ".",
    }
    ext: ClassVar[list[str]] = [".nou", ".rst", ".otl", ".md", ".txt", ""]
    loci: ClassVar[list[str]] = ["doc", "docs", "_doc", "todo", ""]
    """:doc [<name>]
    Search and open appropriate metafile in one of choosen directories
    """

    # TODO: find existing file with any extension.
    # NEED: priority if exists multiple files with same extension
    # -- Though ext=.nou is preferred and default when creating new file.
    def _nearest(self, pwd: str, nm: str, fvalidate: Callable[[str], bool]) -> str | None:
        for d in doc.loci:
            for e in doc.ext:
                path = fs.join(pwd, d, nm + e)
                if fvalidate(path):
                    return path

    def execute(self) -> None:
        nm = self.arg(1) if self.arg(1) else doc.lst["t"]
        if nm == ".":
            # NEED: copy "_tmpl/worklog" instead of using empty file
            # FIX:BET: check/create/open symlinks "today.nou" "tomorrow.nou" "nextweek.nou"
            #   => so you could open them directly from filesystem even without ranger shortcut
            #   => relative symlink will be commited in GIT containing date of commit -- nice historical bisect
            nm = today_date()
        if self.quantifier is not None:
            nm = f"{nm}_{self.quantifier:02d}"
        pwd = self.fm.thisdir.path
        path = self._nearest(pwd, nm, fs.isfile)
        # WARNING: opens nested editor if file don't exists!
        # DEV: check if 'file-chooser' regime and touch file before open
        # if not fs.lexists(path):
        #     open(path, 'a').close()
        if path:
            self.fm.select_file(path)
            self.fm.move(right=1)
        else:
            path = self._nearest(pwd, nm, lambda x: fs.isdir(fs.dirname(x)))
            self.fm.edit_file(path)

    def tab(self, tabnum: int) -> list[str]:  # pyright: ignore[reportIncompatibleMethodOverride]
        return ["doc " + nm for nm in doc.lst.values()]


# NOTE:NEED: in ~/.bashrc or ~/.zshrc save $PWD (not pwd) on trap EXIT
class cd_shelldir(Command):
    lastdir: ClassVar[str] = tmpfile("cwd")
    """:cd_shelldir
    Goes to path from /tmp/<username>/ranger/cwd
    """

    def execute(self) -> None:
        try:
            fname = self.fm.confpath(cd_shelldir.lastdir)
            with open(fname, "r+") as f:
                path = f.readline().rstrip()
                f.seek(0)
                f.truncate()
        except OSError:
            return self.fm.notify(cd_shelldir.lastdir, bad=True)

        # FIXED: expanded pwd symlink teleporting
        # BUG: cd to symlink dir, open ranger, do "cD" to reduce current dir, enter subshell
        #   -> BAD: again inside symlink dir instead of readlinked one
        if path != fs.realpath(self.fm.thisdir.path) and fs.exists(path):
            self.fm.cd(path)

    def tab(self, tabnum: int) -> CompletionResult:  # pyright: ignore[reportIncompatibleMethodOverride]
        return cast(CompletionResult, self._tab_directory_content())  # Generic function


class cd_gitroot(Command):
    def execute(self) -> None:
        from subprocess import CalledProcessError, check_output

        try:
            # cd fm.thisdir.path
            out = check_output(["git", "rev-parse", "--show-toplevel"])
        except CalledProcessError as error:
            self.fm.notify(f"cd_gitroot: {error}", bad=True)
            return
        else:
            path = out[:-1].decode("utf-8")

        if path != fs.realpath(self.fm.thisdir.path) and fs.exists(path):
            self.fm.cd(path)


# Auto cd
class cda(Command):
    def execute(self) -> None:
        if self.arg(1) and self.arg(1)[0] == "-":
            flags = self.arg(1)[1:]
            path = self.rest(2)
        else:
            flags = ""
            path = self.rest(1)

        if path[0:1] == "~":
            path = fs.expanduser(path)
        if path[0:1] != "/":
            path = fs.join(self.fm.thisdir.path, path)

        # Strip :lnum:lpos:
        path = re.sub(r"(?::\d+){1,2}:?$", "", path)

        if "m" in flags or "M" in flags:
            from stat import S_ISDIR

            patt = "/**" if "m" in flags else f"/{today_date()}*/*"
            files = __import__("glob").glob(path + patt, recursive=True)
            files = [x for x in files if not x.endswith(".pyc")]
            if files:
                path = max(
                    (max([st.st_mtime, st.st_ctime]), x)
                    for x in files
                    if not S_ISDIR((st := os.lstat(x)).st_mode)
                )[1]
            else:
                path = max(x for x in __import__("glob").glob(path + "/*"))
        elif fs.islink(path):
            if "l" in flags:
                lpath = os.readlink(path)
                # NOTE: resolve only basename (relative to its dir)
                if lpath.startswith("/"):
                    anchor = fs.realpath(fs.dirname(path))
                    relpath = fs.relpath(fs.realpath(path), anchor)
                    path = fs.join(fs.dirname(path), relpath)  # MAYBE:USE fs.abspath()
                else:
                    path = fs.join(fs.dirname(path), lpath)
            if "L" in flags:
                path = fs.realpath(path)

        # if not fs.lexists(path):
        #     return self.fm.notify("No such: " + path, bad=True)

        if fs.isdir(path):
            self.fm.cd(path)
        elif fs.isfile(path) or fs.islink(path):
            self.fm.select_file(path)
        else:
            self.fm.select_file(path)


class df(Command):
    def execute(self) -> int | None:  # pyright: ignore[reportIncompatibleMethodOverride]
        fls = None
        flags = ""
        if self.arg(1) and self.arg(1)[0] == "-":
            flags = self.arg(1)
            self.shift()
        cmd = self.rest(1).split()

        cidx = list(self.fm.tabs).index(self.fm.current_tab)
        # Cross-tab compare specified tab
        if self.quantifier is not None:
            tidx = self.quantifier
        else:
            tidx = (cidx + 1) % len(self.fm.tabs)
        ctab = self.fm
        ttab = list(self.fm.tabs.values())[tidx]
        csel = len(ctab.thisdir.marked_items)
        tsel = len(ttab.thisdir.marked_items)

        # DEV: df cidx!=tidx: search file with same name in tidx
        #   -- if no such file == show error
        #   BUT: then can't compare different names in tabs fast
        #       -- 'cause need to 'vsel' them before compare
        # DEV: df multiselection to multiselection
        #   => treat like dirs %d %D compare with only selected files
        if cidx == tidx and csel == 0:
            self.fm.notify("curr_tab: select targets to compare", bad=True)
        elif cidx != tidx and csel == 0 and tsel == 0:
            fls = [ctab.thisfile, ttab.thisfile]
        elif cidx == tidx or tsel == 0:
            if csel == 1:
                # Gliding diff in curr_tab
                fls = [ctab.thisdir.marked_items[0], ctab.thisfile]
            elif csel == 2:
                fls = ctab.thisdir.marked_items
            else:
                self.fm.notify("curr_tab: select only one or two files", bad=True)
        elif cidx != tidx:
            if csel == 0 and tsel == 1:
                fls = [ctab.thisfile, ttab.thisdir.marked_items[0]]
            elif csel == 0 and tsel > 1:
                self.fm.notify("next_tab: select only one or zero files", bad=True)
            elif csel == 1 and tsel == 1:
                fls = [t.thisdir.marked_items[0] for t in [ctab, ttab]]
            else:
                self.fm.notify("TBD: uncompatible selection", bad=True)

        if not fls:
            return 1
        elif fls[0] == fls[1]:
            self.fm.notify("Err: refuse to compare the same file", bad=True)
            return 2
        else:
            # DEV: substitute python-like placeholders -> {}, {1}, {2}
            #   else -> append filelist
            cmd += [f.path + ("/" if f.is_directory else "") for f in fls]
            print(cmd)
            self.fm.execute_command(cmd, flags=flags)


class nrenum(Command):
    bmrk: ClassVar[Pattern[str]] = re.compile(r"(.*)\{(\d+)([^}]+?)(\d+)\}$")

    def execute(self) -> None:
        istotal = self.arg(1)[0:2] == "-t"
        if istotal:
            self.shift()
        chg = int(self.arg(1)) if self.arg(1) else 1
        if self.quantifier is not None:
            chg *= self.quantifier

        m = nrenum.bmrk.match(self.fm.thisfile.relative_path)
        if not m:
            return

        name, state = m.group(1), m.group(3)
        total, ready = int(m.group(2)), int(m.group(4))

        if ready == total:
            if state.startswith("@"):
                ready += chg if not istotal else 0
                total += max(0, chg)
        elif ready > total:
            if state.startswith("@"):
                total = ready if chg > 0 else total
        elif ready < total:
            if istotal:
                total += chg
            else:
                ready += chg

        ready = max(ready, 0)
        total = max(total, 0)

        if state.endswith("#") and ready == total:
            state = state[:-1] + "$"
        elif state.endswith("$") and ready < total:
            state = state[:-1] + "#"

        nm = f"{name:s}{{{total:d}{state:s}{ready:d}}}"
        self.fm.execute_console("rename " + nm)


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


class mvsel(Command):
    """:mvsel %any_path

    Move files from current selection to dir on cmdline (OR one of bookmarks)
    """

    def execute(self) -> None:
        dest = self.rest(1)
        self.fm.cut()
        self.fm.paste(dest=dest)
        self.fm.notify(dest)


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
