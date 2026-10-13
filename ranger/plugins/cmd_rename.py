"""cmd_rename: nrenum (progress-counter in name `name{TOTAL<state>READY}`), rename_clip.

## USAGE: :nrenum [-t] [N]   (-t = change TOTAL, else READY; quantifier multiplies N)
## USAGE: :rename_clip       rename cursor file to clipboard text, put the OLD name into clipboard (swap)
## DEPS: clipboard.py (fm.get_clipboard/fm.set_clipboard -- resolved at call time, load order irrelevant)
## MAPS: `,<C-a>` `,<C-x>` `,<C-t>` `,<C-r>` (nrenum), `pr` (rename_clip)
## NOTE: rc.conf passes `quantifier` into nrenum text AND nrenum multiplies by self.quantifier -- probably
##   harmless because execute_console() gives the nested command no quantifier. Check if counts look squared.
"""

from __future__ import annotations

import re
from re import Pattern
from typing import ClassVar

from ranger.api.commands import Command


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


# %ONELINE: map pr eval (lambda x: (fm.set_clipboard(fm.thisfile.basename.encode('utf-8')), cmd('rename ' + x)))(fm.get_clipboard().replace("%", "%%"))
class rename_clipboard(Command):
    """:rename_clip -- swap cursor file name and clipboard (opens prefilled :rename)"""

    def execute(self) -> None:
        fm = self.fm
        new = fm.get_clipboard().replace("%", "%%")  # type: ignore[attr-defined]  # clipboard.py
        fm.set_clipboard(fm.thisfile.basename.encode("utf-8"))  # type: ignore[attr-defined]
        fm.execute_console("rename " + new)
