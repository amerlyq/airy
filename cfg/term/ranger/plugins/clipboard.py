"""
Provide access to clipboard from rc.conf
USE: eval fm.get_clipboard([<p/b/s>])
SEE: http://kendriu.com/how-to-use-pipes-in-python-subprocesspopen-objects
"""

import os
import ranger.api
from subprocess import check_output
from subprocess import Popen, PIPE

old_hook_init = ranger.api.hook_init


def _get(src='b'):
    cmd = ('xsel -o' + src).split()
    return check_output(cmd).decode('utf-8').rstrip()


def _set(data, dst='b'):
    cmd = ('xsel -i' + dst).split()
    xsel = Popen(cmd, stdin=PIPE)
    xsel.communicate(input=data)


def hook_init(fm):
    old_hook_init(fm)
    fm.get_clipboard = _get
    fm.set_clipboard = _set

ranger.api.hook_init = hook_init
