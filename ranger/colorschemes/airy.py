# REF: https://github.com/ranger/ranger/blob/master/doc/colorschemes.md
# DFL: /usr/share/doc/ranger/config/colorschemes/default.py
# VIZ: /usr/lib/python3.9/site-packages/ranger/gui/context.py

import ranger.gui.color as C
from ranger.colorschemes.solarized import Solarized


class Scheme(Solarized):
    def use(self, ctx):
        fg, bg, attr = Solarized.use(self, ctx)
        if ctx.link or ctx.inactive_pane:  # or ctx.marked
            return fg, bg, attr

        if ctx.ext_nou:
            fg = 187  # OR: 22 28 BET?=30 31 174
        elif ctx.wf_log:
            fg = 98

        return fg, bg, attr
