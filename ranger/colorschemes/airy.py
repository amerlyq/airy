# REF: https://github.com/ranger/ranger/blob/master/doc/colorschemes.md
# DFL: /usr/share/doc/ranger/config/colorschemes/default.py
# VIZ: /usr/lib/python3.9/site-packages/ranger/gui/context.py

import curses

import ranger.gui.color as C
from ranger.colorschemes.solarized import Solarized


class Scheme(Solarized):
    def use(self, ctx):
        # NOTE: only existing annexed symlinks must mimic to real files
        annexed = ctx.annexed and ctx.good
        if annexed:
            ctx.link = False
        fg, bg, attr = Solarized.use(self, ctx)
        if annexed:
            attr |= curses.A_ITALIC
            return fg, bg, attr
        if ctx.inactive_pane:  # or ctx.marked
            return fg, bg, attr

        # E.G: aliases to *.nou
        if ctx.link:
            return fg, bg, attr

        if ctx.ext_nou:
            fg = 187  # OR: 22 28 BET?=30 31 174
        elif ctx.wf_log:
            fg = 98
        elif ctx.wf_todo:
            fg = 98
        elif ctx.wf_ref:
            fg = 28
        elif ctx.wf_gen:
            fg = 94
        elif ctx.wf_misc:
            fg = 67

        return fg, bg, attr
