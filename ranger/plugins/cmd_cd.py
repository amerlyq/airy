"""cmd_cd: directory jumpers: cd_shelldir, cd_gitroot, cda, cd_samedur.

## ARCH: all end in fm.cd()/fm.select_file() => history_navi.py wrapper sees them as "jump" (recorded), not "step"
## CONFLICT(history_navi.py): cda flags `l`/`L` (follow symlink) overlap `cd_symlink1` (`cl`): cda resolves
##   the link path textually, cd_symlink1 keeps a strict history chain. Prefer cd_symlink1 for interactive use.
## CONFLICT(vdsym*): `cz` (cd_samedur) and `cg` (rc.conf: /t/dupnm/<name>) are the same family as vdsym's
##   dashboard jumps (`--dashboard=/t/bnm`). ALT: fold both into vdsym as `--source=...` actions.
##   cda's ":lnum:lpos:" stripping probably duplicates vdsym `--modifiers=numeric` (unverified).
## DEBUG: cd_shelldir reads+truncates base_util.tmpfile("cwd"), written by shell trap (see NOTE:NEED below)
"""

from __future__ import annotations

import os
import re
import stat
from os import path as fs
from typing import ClassVar, cast

from ranger.api.commands import Command

try:
    from plugins.base_util import CompletionResult, tmpfile, today_date
except ModuleNotFoundError:
    from base_util import CompletionResult, tmpfile, today_date


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

        if "M" in flags:

            def newest_entry(directory):
                entries = []
                try:
                    entries = [entry.path for entry in os.scandir(directory)]
                except OSError:
                    return []
                candidates = []
                for entry in entries:
                    if entry.endswith(".pyc"):
                        continue
                    try:
                        mode = os.lstat(entry).st_mode
                    except OSError:
                        continue
                    if stat.S_ISDIR(mode):
                        nested = newest_entry(entry)
                        candidates.extend(nested or [entry])
                    else:
                        candidates.append(entry)
                return candidates

            candidates = []
            for date_directory in __import__("glob").glob(path + f"/{today_date()}*"):
                candidates.extend(newest_entry(date_directory))
            if candidates:
                path = max(
                    (
                        max(os.lstat(candidate).st_mtime, os.lstat(candidate).st_ctime),
                        candidate,
                    )
                    for candidate in candidates
                )[1]
            else:
                candidates = list(__import__("glob").glob(path + f"/{today_date()}*"))
                path = max(candidates) if candidates else path
        elif "m" in flags:
            from stat import S_ISDIR

            files = __import__("glob").glob(path + "/**", recursive=True)
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


# %ONELINE: map cz eval import subprocess; lines = subprocess.check_output(f"find /t/samedur0 -name '*／{fm.thisfile.basename}' -print", shell=True, text=True).splitlines(); fm.select_file(lines[0]) if lines else fm.notify("No /t/samedur0/ name found.")
class cd_samedur_ji(Command):
    """:cd_samedur

    Select first /t/samedur0/**/*／<basename of cursor file>  (U+FF0F in the name = flattened path separator).
    """

    root: ClassVar[str] = "/t/samedur0"

    def execute(self) -> None:
        from subprocess import CalledProcessError, check_output

        f = self.fm.thisfile
        if f is None:
            return
        # find(1) -name glob: escape *?[\ in the name. FIXED: original interpolated the name into a shell string
        pat = "*／" + re.sub(r"([*?\[\\])", r"\\\1", f.basename)
        try:
            out = check_output(["find", self.root, "-name", pat, "-print"], text=True)
        except CalledProcessError as e:
            return self.fm.notify(f"cd_samedur: {e}", bad=True)
        lines = out.splitlines()
        if lines:
            self.fm.select_file(lines[0])
        else:
            self.fm.notify("No /t/samedur0/ name found.")


class cd_samedur(Command):
    """:cd_samedur — dashboard files within duration tolerance across VD cache

    Count 1–4 selects ±200/500/1000/4000 ms; larger counts use ±200 ms.
    """

    tolerances: ClassVar[tuple[int, ...]] = (200, 500, 1000, 4000)

    def execute(self) -> None:
        try:
            from plugins import vdconf, vdprobe, vdsym
        except ImportError:
            import vdconf
            import vdprobe
            import vdsym

        f = self.fm.thisfile
        if f is None:
            return
        count = self.quantifier or 1
        tolerance = (
            self.tolerances[count - 1]
            if 1 <= count <= len(self.tolerances)
            else self.tolerances[0]
        )
        try:
            source = vdprobe.info(f.path, os.stat(f.path))
        except OSError:
            source = None
        if source is None:
            return self.fm.notify(f"No duration available for {f.basename}.", bad=True)

        target_ms = source[0]
        roots = [root for root in vdsym.vdsym.roots() if fs.isdir(root)]
        if not roots:
            return self.fm.notify("No VD cache roots are available.", bad=True)
        vdprobe.build_duration_index(roots)
        matches = vdprobe.duration_matches(target_ms, tolerance)
        if not matches:
            return self.fm.notify(
                f"No same-duration files within ±{tolerance} ms.", duration=2
            )
        dest = fs.join(vdconf.DASHBOARD_ROOT, "samedur", str(tolerance), f.basename)
        vdsym.make_dashboard(self.fm, matches, dest)
