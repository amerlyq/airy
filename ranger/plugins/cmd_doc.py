"""cmd_doc: `:doc [<name>]` -- open/create metafile (todo, worklog, ...) in the nearest of doc/ docs/ _doc/ todo/ .

## USAGE: :doc  |  :doc .  (today's date name; hour offset in rutil.today_date)  |  <N>:doc  (suffix _NN)
## MAPS: `O<k>` generated in rc.conf from `doc.lst` (see rc.conf: `eval for k,nm in ...doc.lst`)
## ARCH: lst = key->name table (single source for maps AND <Tab>), ext/loci = lookup order (first hit wins)
## EXT: add a kind = one line in `lst`; add a dir/extension = one line in `loci`/`ext`
"""
from __future__ import annotations

from collections.abc import Callable
from os import path as fs
from typing import ClassVar

from ranger.api.commands import Command

from plugins.rutil import today_date


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
    def _nearest(
        self, pwd: str, nm: str, fvalidate: Callable[[str], bool]
    ) -> str | None:
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
