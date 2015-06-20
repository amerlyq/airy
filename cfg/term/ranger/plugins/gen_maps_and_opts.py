# vim: fileencoding=utf-8

import os
import ranger.api
old_hook_init = ranger.api.hook_init


def aura_options(fm):
    # default, jungle, snow, solarized
    fpath = os.path.expanduser('~/.cache/airy/theme')
    try:
        with open(fm.confpath(fpath), 'r') as f:
            theme = f.readline()
    except IOError:
        theme = "dark"
    theme = {"dark": "solarized", "light": "solarized"
             }.get(theme, "solarized")
    fm.execute_console("set colorscheme {}".format(theme))


def aura_pathes(fm):
    ## Generate key bindings for fast directory jumping
    fpathes = os.path.expanduser('~/.shell/pathes')
    lst = []
    try:
        fname = fm.confpath(fpathes)
        with open(fname, 'r') as f:
            lst = f.readlines()
    except IOError:
        return fm.notify(fpathes, bad=True)

    lst = [l.split('#', 1)[0].strip().split(None, 1) for l in lst]
    lst = filter(lambda e: len(e) > 1, lst)
    # ERR: ranger sorts by 2nd column by default... Qs: How to alterate?
    for e in sorted(lst, key=lambda l: l[0]):  # reverse=True
        fm.execute_console("map {} cd {}".format(*e))


def hook_init(fm):
    old_hook_init(fm)
    aura_options(fm)
    aura_pathes(fm)

    for fmt in ("\{0}", "<a-{0}>"):
        for i in range(9):
            fm.execute_console(("map " + fmt + " tab_open {0}").format(i+1))


ranger.api.hook_init = hook_init
