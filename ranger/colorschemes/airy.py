# REF: https://github.com/ranger/ranger/blob/master/doc/colorschemes.md
# DFL: /usr/share/doc/ranger/config/colorschemes/default.py
# VIZ: /usr/lib/python3.9/site-packages/ranger/gui/context.py

import ranger.gui.color as C
from ranger.colorschemes.solarized import Solarized


class Scheme(Solarized):
    def use(self, context):
        fg, bg, attr = Solarized.use(self, context)

        if (
            context.ext_nou
            # and not context.marked
            and not context.link
            and not context.inactive_pane
        ):
            fg = 187  # OR: 22 28 BET?=30 31 174
            # fg = C.green

        return fg, bg, attr
