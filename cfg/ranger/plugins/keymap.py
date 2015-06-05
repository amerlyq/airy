
import os
import ranger.api
old_hook_init = ranger.api.hook_init


def hook_init(fm):
    old_hook_init(fm)

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


ranger.api.hook_init = hook_init
