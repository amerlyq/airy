# :delete prompts (Esc/Enter never delete), symlink-to-symlink, directories, only inside VD roots; cv on an unused symlink; cV dashboard name; refresh modes (default/norefresh/visited); cd signal.
import os
import sys
import tempfile
import time
import types
from os import path as fs

import vdsym as M

import paths  # noqa: F401  (plugin dir on sys.path, isolated state)

M.DANGLING_MONITOR = (
    False  # covered by test4; these fixtures leave dangling links on purpose
)


class Entry:
    def __init__(s, path):
        s.path = path
        s.basename = fs.basename(path)
        s.relative_path = s.basename
        s.is_link = fs.islink(path)


class Console:
    def __init__(s):
        s.q = []

    def ask(s, text, cb, choices=None):
        s.q.append((text, cb, choices))

    def _pop(s, i):
        text, cb, ch = s.q.pop(0)
        cb(ch[i])  # ranger: Enter -> choices[0], Esc -> choices[1]

    def enter(s):
        s._pop(0)

    def esc(s):
        s._pop(1)

    def answer(s, a):
        text, cb, ch = s.q.pop(0)
        assert a in ch
        cb(a)


class FM:
    def __init__(s, cwd):
        s.notes = []
        s.deleted = []
        s.cds = []
        s.selected = None
        s.ui = types.SimpleNamespace(console=Console())
        s.settings = types.SimpleNamespace(confirm_on_delete="always")
        s.sel = []
        s.copy_buffer = set()
        s.cmds = []
        s.thisdir = types.SimpleNamespace(path=cwd, files=[], marked_items=[])
        s.thistab = types.SimpleNamespace(get_selection=lambda: s.sel)
        s.thisfile = None

    def notify(s, m, **k):
        s.notes.append(str(m))

    def delete(s, files=None):
        s.deleted.append(list(files))

    def cd(s, d):
        s.cds.append(d)

    def select_file(s, p):
        s.selected = p

    def execute_command(s, c, flags=""):
        s.cmds.append(c)

    def move(s, **k):
        pass


base = tempfile.mkdtemp(prefix="vdt2")
view, d1, d2, outside = [fs.join(base, x) for x in ("view", "vd1", "vd2", "outside")]
for d in (view, d1, d2, outside):
    os.makedirs(d)
M.vdsym.view_root = view
M.vdsym.data_roots = (d1, d2)
M.DASHBOARD_ROOT = fs.join(base, "bnm")


def w(p):
    os.makedirs(fs.dirname(p), exist_ok=True)
    open(p, "w").close()


def mk(line, fm, thisfile=None):
    M.Command.fm = fm
    c = M.vdsym(line)
    fm.thisfile = Entry(thisfile) if thisfile else None
    return c


M.delete._copy_names = lambda self, names: True


def start_delete(fm):
    M.Command.fm = fm
    fm.thisfile = fm.sel[0] if fm.sel else None
    d = M.delete("delete")
    d.execute()


M._cache.warmed = True  # keep the warm thread out of tests

# ---- Esc / Enter never delete
real = fs.join(d1, "a/real.mp4")
w(real)
os.symlink(real, fs.join(view, "v1"))
for key in ("enter", "esc"):
    fm = FM(fs.join(d1, "a"))
    fm.sel = [Entry(real)]
    start_delete(fm)
    fm.ui.console.enter()  # stock confirm: Enter == "n"
    assert fm.deleted == [] and not fm.ui.console.q
    start_delete(fm)
    fm.ui.console.answer("y")  # confirm -> symlink prompt appears
    assert len(fm.ui.console.q) == 1
    getattr(fm.ui.console, key)()
    assert fm.deleted == [] and fm.cds == [], (key, fm.deleted, fm.cds)
# explicit y still deletes; n -> dashboard
fm = FM(fs.join(d1, "a"))
fm.sel = [Entry(real)]
start_delete(fm)
fm.ui.console.answer("y")
fm.ui.console.answer("y")
assert fm.deleted == [["real.mp4"]]
fm = FM(fs.join(d1, "a"))
fm.sel = [Entry(real)]
start_delete(fm)
fm.ui.console.answer("y")
fm.ui.console.answer("n")
assert fm.deleted == [] and fm.cds[-1].endswith("bnm/real.mp4")
# replace prompt: Enter and Esc quit, don't replace
w(fs.join(d1, "a/new.mp4"))
fm = FM(fs.join(d1, "a"))
c = mk("vdsym --action=replace --source=basename --target=yanked", fm, thisfile=real)
fm.copy_buffer = {Entry(fs.join(d1, "a/new.mp4"))}
c.execute()
fm.ui.console.esc()
assert fs.realpath(fs.join(view, "v1")) == real
c = mk("vdsym --action=replace --source=basename --target=yanked", fm, thisfile=real)
c.execute()
fm.ui.console.enter()
assert fs.realpath(fs.join(view, "v1")) == real
print("esc ok")

# ---- deleting a symlink: only links passing THROUGH it count (symlink-to-symlink)
alias = fs.join(d1, "a/alias.mp4")
os.symlink("real.mp4", alias)  # relative alias in vd root
os.symlink(alias, fs.join(view, "via_alias"))  # view -> alias -> real
os.symlink(
    fs.join(view, "via_alias"), fs.join(view, "via_via")
)  # view -> view -> alias -> real
fm = FM(fs.join(d1, "a"))
fm.sel = [Entry(alias)]
start_delete(fm)
fm.ui.console.answer("y")
q = fm.ui.console.q[0][0]
print(q)
assert q.startswith("2 symlink(s)") and "v1" not in q, q
fm.ui.console.answer("c")
# deleting the real file warns about all (v1, via_alias, via_via, alias)
print(sorted(fs.basename(l) for l in M.find_backlinks([real])))
assert sorted(fs.basename(l) for l in M.find_backlinks([real])) == [
    "alias.mp4",
    "v1",
    "via_alias",
    "via_via",
]
# deleting selection that contains the links too: nothing left to warn about
fm = FM(fs.join(d1, "a"))
fm.sel = [Entry(real), Entry(alias)]
M.Command.fm = fm
# alias lives in d1/a; the view links are not in selection => still warn
start_delete(fm)
fm.ui.console.answer("y")
assert fm.ui.console.q
fm.ui.console.answer("c")

# ---- outside the VD roots: no scan at all
orig = M.find_backlinks
M.find_backlinks = lambda p: (_ for _ in ()).throw(AssertionError("scanned"))
o = fs.join(outside, "x.mp4")
w(o)
os.symlink(o, fs.join(view, "to_outside"))
fm = FM(outside)
fm.sel = [Entry(o)]
start_delete(fm)
fm.ui.console.answer("y")
assert fm.deleted == [["x.mp4"]]
M.find_backlinks = orig

# ---- directory deletion
w(fs.join(d2, "dir/inner/f.mp4"))
os.symlink(fs.join(d2, "dir/inner/f.mp4"), fs.join(view, "into_dir"))
os.symlink(fs.join(d2, "dir/inner"), fs.join(view, "to_inner"))
os.symlink(
    fs.join(d2, "dir/self"), fs.join(d2, "dir/self_link")
)  # dies with the dir => not counted
fm = FM(d2)
fm.sel = [Entry(fs.join(d2, "dir"))]
start_delete(fm)
fm.ui.console.answer("y")
q = fm.ui.console.q[0][0]
print(q)
assert q.startswith("2 symlink(s)"), q
fm.ui.console.answer("c")

# ---- cv on a symlink nobody references: notify, no silent self-jump
lonely = fs.join(d1, "a/lonely_alias.mp4")
os.symlink("real.mp4", lonely)
fm = FM(fs.join(d1, "a"))
c = mk(
    "vdsym --action=autojump1,dashboard,jump --source=basename --modifiers=links-only --dashboard=/t/bnm",
    fm,
    thisfile=lonely,
)
c.execute()
print(fm.notes[-1], fm.selected, fm.cds)
assert "No matches" in fm.notes[-1] and fm.selected is None and not fm.cds
# and still works on a real file with views
c = mk(
    "vdsym --action=autojump1,dashboard,jump --source=basename --modifiers=links-only --dashboard=/t/bnm",
    fm,
    thisfile=fs.join(d2, "dir/inner/f.mp4"),
)
fm.selected = None
c.execute()
assert fm.selected and fm.selected.endswith("into_dir"), fm.selected

# ---- cV: dashboard named after cursor file, not 1st selected
inner = fs.join(d2, "dir/inner/f.mp4")
fm = FM(view)
fm.sel = [Entry(real), Entry(inner)]
c = mk(
    "vdsym --action=dashboard --source=selection --modifiers=links-only --multiple --dashboard="
    + M.DASHBOARD_ROOT,
    fm,
    thisfile=inner,
)
c.execute()
print(fm.cds, fm.notes)
assert fm.cds[-1].endswith("bnm/f.mp4"), fm.cds

# ---- default refresh sees new links; norefresh doesn't
os.symlink(fs.join(d2, "dir/inner/f.mp4"), fs.join(view, "fresh2"))
fm = FM(view)
c = mk("vdsym --modifiers=links-only -- f.mp4", fm)
assert any(m.endswith("fresh2") for m in c._matches())
os.symlink(fs.join(d2, "dir/inner/f.mp4"), fs.join(view, "fresh3"))
c = mk("vdsym --modifiers=links-only,norefresh -- f.mp4", fm)
assert not any(m.endswith("fresh3") for m in c._matches())
c = mk("vdsym --modifiers=links-only,norefresh,view -- f.mp4", fm)
c = mk("vdsym --action=refresh --modifiers=links-only -- f.mp4", fm)
assert any(m.endswith("fresh3") for m in c._matches())

# ---- visited mode: only dirs visited since last seek are rescanned
M.REFRESH = "visited"
os.symlink(fs.join(d2, "dir/inner/f.mp4"), fs.join(view, "fresh4"))
c = mk("vdsym --modifiers=links-only -- f.mp4", fm)
assert not any(m.endswith("fresh4") for m in c._matches())
M._on_cd(view)  # ranger cd'd into the view dir
c = mk("vdsym --modifiers=links-only -- f.mp4", fm)
assert any(m.endswith("fresh4") for m in c._matches())
# new subdir with a new link, found because the nearest cached ancestor is rescanned as a subtree
os.makedirs(fs.join(view, "newdir/deeper"))
os.symlink(fs.join(d2, "dir/inner/f.mp4"), fs.join(view, "newdir/deeper/fresh5"))
M._on_cd(fs.join(view, "newdir"))
c = mk("vdsym --modifiers=links-only -- f.mp4", fm)
assert any(m.endswith("fresh5") for m in c._matches())
# dashboard marks target dirs
os.symlink(fs.join(d2, "dir/inner/f.mp4"), fs.join(view, "fresh6"))
M.make_dashboard(fm, [fs.join(view, "fresh6")], fs.join(base, "bnm/zz"))
c = mk("vdsym --modifiers=links-only -- f.mp4", fm)
assert any(m.endswith("fresh6") for m in c._matches())
M.REFRESH = "validate"
print("refresh ok")

# ---- cd hook: warm-up only under VD roots
M._cache.warmed = False
started = []
import threading

real_thread = threading.Thread


class T:
    def __init__(s, target, **k):
        s.t = target

    def start(s):
        started.append(1)


M.threading.Thread = T
M._on_cd(outside)
assert not started and not M._cache.warmed
M._on_cd(fs.join(d1, "a"))
assert started and M._cache.warmed
M._on_cd(fs.join(d1, "a"))
assert len(started) == 1
M.threading.Thread = real_thread
sig = types.SimpleNamespace(new=types.SimpleNamespace(path=fs.join(d2, "dir")))
M._on_cd_signal(sig)
assert fs.join(d2, "dir") in M._cache.visited
print("OK2")
