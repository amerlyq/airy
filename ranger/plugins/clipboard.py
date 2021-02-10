"""
Provide access to clipboard from rc.conf
USE: eval fm.get_clipboard([<p/b/s>])
SEE: http://kendriu.com/how-to-use-pipes-in-python-subprocesspopen-objects
"""

import os
from subprocess import PIPE, CalledProcessError, run

import ranger.api
from ranger.ext.shell_escape import shell_quote

old_hook_init = ranger.api.hook_init


def hook_init(fm):
    old_hook_init(fm)

    def _xc(**kw):
        kw.setdefault("check", True)
        kw.setdefault("stdout", PIPE)
        try:
            rc = run(**kw)
            if kw["stdout"]:
                return rc.stdout.decode().rstrip(os.linesep)
        except CalledProcessError as exc:
            fm.notify(exc, bad=True)
        return ""

    fm.get_clipboard = lambda: _xc(args=["xco"])
    fm.get_clipboard_q = lambda: shell_quote(_xc(args=["xco"]))
    fm.set_clipboard = lambda x: _xc(args=["xci"], input=x, stdout=None)


ranger.api.hook_init = hook_init
