import importlib
import os
import sys
import tempfile
import threading
import time
import types
from os import path as fs

import ranger
import vdsym as M
from ranger.core.actions import Actions
from ranger.core.shared import FileManagerAware, SettingsAware
from ranger.core.tab import Tab

import paths  # noqa: F401  (plugin dir on sys.path, isolated state)


class Entry:
    def __init__(s, p):
        s.path = p
        s.basename = fs.basename(p)
        s.dirname = fs.dirname(p)
        s.relative_path = s.basename
        s.is_link = fs.islink(p)

    def __hash__(s):
        return hash(s.path)

    def __eq__(s, o):
        return getattr(o, "path", None) == s.path


class Console:
    def __init__(s):
        s.q = []

    def ask(s, text, cb, choices=None):
        s.q.append((text, cb, choices))

    def _pop(s, i):
        text, cb, ch = s.q.pop(0)
        cb(ch[i])

    def enter(s):
        s._pop(0)

    def esc(s):
        s._pop(1)

    def answer(s, a):
        text, cb, ch = s.q.pop(0)
        assert a in ch, (a, ch)
        cb(a)


class FM(Actions):
    def __init__(s, cwd):
        s.notes = []
        s.cmds = []
        s.cds = []
        s.deleted = []
        s.queue = []
        s.sel = []
        s.copy_buffer = set()
        s.do_cut = False
        s.console = Console()
        s.ui = types.SimpleNamespace(
            console=s.console,
            termsize=(24, 80),
            browser=types.SimpleNamespace(
                main_column=types.SimpleNamespace(request_redraw=lambda: None)
            ),
        )
        s.settings = types.SimpleNamespace(confirm_on_delete="always")
        s.thisdir = types.SimpleNamespace(
            path=cwd, files=[], marked_items=[], pointer=0, correct_pointer=lambda: None
        )
        s.thistab = types.SimpleNamespace(path=cwd, get_selection=lambda: s.sel)
        s.loader = types.SimpleNamespace(add=lambda l, append=False: s.queue.append(l))
        s.tags = types.SimpleNamespace(
            tags={},
            remove=lambda p: None,
            dump=lambda: None,
            update_path=lambda a, b: None,
        )
        s.bookmarks = types.SimpleNamespace(update_path=lambda a, b: None)
        s.thisfile = None
        s.selected = None

    def select(s, *paths):
        s.sel = [Entry(p) for p in paths]
        s.thisdir.files = list(s.sel)
        s.thisfile = s.sel[0]

    def delete(s, files=None):
        s.deleted.append(list(files))
        for f in files:
            p = fs.join(s.thisdir.path, f)
            if fs.lexists(p):
                os.unlink(p)

    def notify(s, m, **k):
        s.notes.append(str(m))

    def execute_command(s, c, flags=""):
        s.cmds.append(c)

    def cd(s, d):
        s.cds.append(d)

    def select_file(s, p):
        s.selected = p

    def move(s, **k):
        pass

    def get_directory(s, p):
        return types.SimpleNamespace(load_content=lambda: None)

    def run_loader(s):
        for l in s.queue:
            for _ in l.load_generator:
                pass
        s.queue.clear()


def newfm(cwd):
    fm = FM(cwd)
    FileManagerAware.fm_set(fm)
    SettingsAware.settings_set(
        types.SimpleNamespace(size_in_bytes=False, confirm_on_delete="always")
    )
    M.Command.fm = fm
    return fm
