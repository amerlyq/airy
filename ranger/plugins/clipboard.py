"""
Provide access to clipboard from rc.conf
USE: eval fm.get_clipboard([<p/b/s>])
SEE: http://kendriu.com/how-to-use-pipes-in-python-subprocesspopen-objects
"""

import ranger.api
from ranger.ext.shell_escape import shell_quote
from subprocess import check_output, CalledProcessError

old_hook_init = ranger.api.hook_init


def _xsel(args, **kw):
    cmd = ('xsel ' + args).split()
    try:
        return check_output(cmd, universal_newlines=True, **kw).rstrip()
    except CalledProcessError as e:
        print(e)
        return ''


def hook_init(fm):
    old_hook_init(fm)
    fm.get_clipboard = lambda r='b': _xsel('-o' + r)
    fm.get_clipboard_q = lambda r='b': shell_quote(_xsel('-o' + r))

    fm.set_clipboard = lambda t, r='b': _xsel('-i' + r, input=t)

ranger.api.hook_init = hook_init
