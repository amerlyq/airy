import os
import shutil
import sys
import tempfile
from pathlib import Path
import time
import types

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import ranger
from ranger.container.settings import Settings
from ranger.core.fm import FM
from ranger.core.shared import FileManagerAware, SettingsAware
from ranger.core.tab import Tab


class Col:  # ui stubs
    def request_redraw(self):
        pass


class Browser:
    main_column = Col()


class Console:
    def __init__(self):
        self.answers = []
        self.asked = []

    def ask(self, text, cb, choices):
        self.asked.append(text)
        cb(self.answers.pop(0))


class UI:
    browser = Browser()
    console = Console()
    termsize = (24, 80)
    status = Col()
    titlebar = Col()

    def redraw_main_column(self):
        pass

    def __getattr__(self, n):
        return lambda *a, **k: None


def make_fm(cwd):
    from ranger.ext.signals import SignalDispatcher

    ui = UI()
    fm = FM(ui=ui, paths=[cwd])
    ranger.fm = fm
    FileManagerAware.fm = fm
    SettingsAware.settings = Settings()
    ranger.args = types.SimpleNamespace(
        clean=True,
        confdir=os.path.join(tempfile.gettempdir(), "ranger-test-conf"),
        cachedir=os.path.join(tempfile.gettempdir(), "ranger-test-cache"),
        debug=False,
    )
    fm.tabs = {}
    tab = Tab(cwd)
    fm.tabs[1] = tab
    fm.current_tab = 1
    fm.thistab = tab
    fm.notes = []
    fm.tags = types.SimpleNamespace(tags={}, remove=lambda p: None, dump=lambda: None)
    fm.notify = lambda msg, duration=4, bad=False, exception=None: fm.notes.append(
        (str(msg), bad)
    )
    return fm


def pump(fm, n=400):
    for _ in range(n):
        if not fm.loader.has_work():
            break
        fm.loader.work()
