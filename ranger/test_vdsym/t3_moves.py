# fm.cut / fm.paste / :rename guards on the real ranger Actions + CopyLoader: prompt, U (update) / R (replace), recovery log, pics layout, racy mtimes, hooks (Tab.enter_dir untouched), busy cache lock.
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

    def select(s, *paths):
        s.sel = [Entry(p) for p in paths]
        s.thisdir.files = list(s.sel)
        s.thisfile = s.sel[0]

    def notify(s, m, **k):
        s.notes.append(str(m))

    def execute_command(s, c, flags=""):
        s.cmds.append(c)

    def cd(s, d):
        s.cds.append(d)

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


base = tempfile.mkdtemp(prefix="vdt3")
view, d1, d2, outside = [fs.join(base, x) for x in ("view", "vd1", "vd2", "outside")]
for d in (view, d1, d2, outside):
    os.makedirs(d)
M.vdsym.view_root = view
M.vdsym.data_roots = (d1, d2)
M.DASHBOARD_ROOT = fs.join(base, "bnm")
M.RECOVERY_LOG = fs.join(base, "state/moves.log")
M._cache.warmed = True


def w(p):
    os.makedirs(fs.dirname(p), exist_ok=True)
    open(p, "w").close()


def rel(ps):
    return sorted(fs.relpath(p, base) for p in ps)


# ---------- hooks: not a Tab.enter_dir wrapper, patched exactly once, survive re-exec
assert Tab.enter_dir.__code__.co_filename.endswith("core/tab.py"), (
    "Tab.enter_dir must stay untouched"
)
orig = sys.modules["_vdsym_shared"].orig
assert orig[(Actions, "cut")] is not Actions.cut
importlib.reload(M)  # same source => same cache, wrappers re-made
assert orig[(Actions, "cut")].__qualname__ == "Actions.cut"
M.vdsym.view_root = view
M.vdsym.data_roots = (d1, d2)
M.DASHBOARD_ROOT = fs.join(base, "bnm")
M.RECOVERY_LOG = fs.join(base, "state/moves.log")
bound = []


class SigFM:
    def signal_bind(s, name, fn):
        bound.append((name, fn))


f = SigFM()
M._bind_cd(f)
M._bind_cd(f)
assert len(bound) == 1 and bound[0][0] == "cd"
print("hooks ok")

# ---------- pics: <dnum> / <dnum>-* under "<datepfx>-*-pics[-*]"
w(fs.join(d1, "2024-05-pics/123-foo/123-45.webp"))
w(fs.join(d1, "2024-05-pics/123-foo/123-0045.mp4"))
w(fs.join(d1, "2024-05-pics/123-foo/123-00045.gif"))
w(fs.join(d1, "2024-05-pics/123-foo/123-000045.webp"))
w(fs.join(d1, "2024-05-pics/123-foo/123-0000045.webp"))  # 4 zeroes: out of range
w(fs.join(d1, "2024-05-pics-x/123/123-45.gif"))
w(fs.join(d1, "2024-05-pics/1234/1234-45.webp"))
w(fs.join(d1, "2024-pics/123/123-45.webp"))  # parent doesn't match datepfx-*-pics
w(fs.join(d1, "2024-05-pics/readme.txt"))
w(fs.join(d1, "2024-05-pics/misc/123-45.webp"))


def mk(line, fm, thisfile=None):
    M.Command.fm = fm
    c = M.vdsym(line)
    fm.thisfile = Entry(thisfile) if thisfile else None
    return c


fm = newfm(base)
c = mk("vdsym --modifiers=numeric -- 123-45.html", fm)
got = rel(c._matches())
print(got)
assert got == sorted(
    [
        "vd1/2024-05-pics/123-foo/123-45.webp",
        "vd1/2024-05-pics/123-foo/123-0045.mp4",
        "vd1/2024-05-pics/123-foo/123-00045.gif",
        "vd1/2024-05-pics-x/123/123-45.gif",
    ]
)  # 123-000045 (4 zeroes) is out of range
c = mk("vdsym --modifiers=numeric -- 123-045.webp", fm)
assert rel(c._matches()) == got  # an image name finds the same set
c = mk("vdsym --modifiers=numeric -- 1234-45.html", fm)
assert rel(c._matches()) == ["vd1/2024-05-pics/1234/1234-45.webp"]
idx = M._cache.ensure(M.vdsym.roots()).index
assert (
    "123-0045.mp4" not in idx.names
    and "readme.txt" in idx.names
    and "123-foo" in idx.names
)  # payload dirs unlisted, siblings normal
assert "123-45.webp" in idx.names and all(
    "misc" in p or "2024-pics" in p for p in idx.names["123-45.webp"]
)
print("pics ok")

# ---------- racy mtimes: a change within the same mtime tick is still seen; no needless rebuild
w(fs.join(view, "racy/a"))
M._cache.ensure(M.vdsym.roots(), "validate")
v0 = M._cache.rootver[view]
M._cache.ensure(M.vdsym.roots(), "validate")
assert M._cache.rootver[view] == v0, "same content must not bump the version"
st = os.stat(fs.join(view, "racy"))
w(fs.join(view, "racy/b"))
os.utime(fs.join(view, "racy"), ns=(st.st_atime_ns, st.st_mtime_ns))  # restore mtime
v = M._cache.ensure(M.vdsym.roots(), "validate")
assert "b" in v.index.names, "racy dir must be re-read"
print("racy ok")

# ---------- a movable file with views, clips, a chain and a dangling-to-be
real = fs.join(d1, "a/movie.mp4")
w(real)
w(fs.join(d1, "a/movie_00m33s6.mp4"))


def links():
    for p in [fs.join(view, "abs"), fs.join(view, "sub/rel"), fs.join(view, "chain")]:
        if fs.lexists(p):
            os.unlink(p)
    os.makedirs(fs.join(view, "sub"), exist_ok=True)
    os.symlink(real, fs.join(view, "abs"))
    os.symlink("../../vd1/a/movie.mp4", fs.join(view, "sub/rel"))
    os.symlink(fs.join(view, "abs"), fs.join(view, "chain"))


links()

# ---------- staged links keep an identifiable old spelling until the file moved
txn_old = fs.join(d1, "a/txn.mp4")
txn_new = fs.join(d2, "txn.mp4")
txn_link = fs.join(view, "txn")
w(txn_old)
os.symlink(txn_old, txn_link)
txn_fm = newfm(fs.join(d1, "a"))
txn_job = M._MoveJob(
    txn_fm,
    {txn_old: txn_new},
    {txn_old: "U"},
    M.find_hits([txn_old], dashboards=True),
)
assert txn_job.stage() and fs.lexists(txn_link) and not fs.exists(txn_link)
assert any(".vdsym-old-" in name for name in os.listdir(view))
os.rename(txn_old, txn_new)
txn_job.finish()
assert fs.realpath(txn_link) == txn_new
assert not any(".vdsym-old-" in name for name in os.listdir(view))
os.unlink(txn_link)


def full_cycle(choice, dest, cancel=None, key=None):
    fm = newfm(fs.join(d1, "a"))
    fm.select(real)
    fm.thistab.path = fs.join(d1, "a")
    fm.cut()
    assert len(fm.console.q) == 1
    text = fm.console.q[0][0]
    if key:
        getattr(fm.console, key)()
        return fm, text
    fm.console.answer(choice)
    fm.thistab.path = dest
    fm.paste()
    fm.run_loader()
    return fm, text


# print list + recovery log happen before the prompt
fm, text = full_cycle("U", d2)
print(text)
assert "3 symlink(s)" in text and "1 clip(s)" in text and "U=update" in text
assert "movie_00m33s6.mp4" not in text
assert (
    fm.cmds
    and "abs" in fm.cmds[0]
    and "chain" in fm.cmds[0]
    and "sub/rel" in fm.cmds[0]
)
log = open(M.RECOVERY_LOG).read()
assert "link " + fs.join(view, "abs") in log and "cut" in log
new = fs.join(d2, "movie.mp4")
assert fs.exists(new) and not fs.exists(real)
assert os.readlink(fs.join(view, "abs")) == new
assert os.readlink(fs.join(view, "sub/rel")) == "../../vd2/movie.mp4", os.readlink(
    fs.join(view, "sub/rel")
)
assert os.readlink(fs.join(view, "chain")) == fs.join(
    view, "abs"
)  # chain untouched, still resolves
assert fs.realpath(fs.join(view, "chain")) == new
assert any("2 updated" in n for n in fm.notes), fm.notes
assert sorted(fs.basename(h.link) for h in M.find_hits([new])) == [
    "abs",
    "chain",
    "rel",
]  # cache already knows
print("U ok", fm.notes[-1])

# R: new links named exactly like the file, same dirs, old ones gone
os.rename(new, real)
links()
fm, text = full_cycle("R", d2)
assert (
    not fs.lexists(fs.join(view, "abs"))
    and fs.islink(fs.join(view, "movie.mp4"))
    and fs.islink(fs.join(view, "sub/movie.mp4"))
)
assert (
    fs.realpath(fs.join(view, "movie.mp4")) == new
    and fs.realpath(fs.join(view, "sub/movie.mp4")) == new
)
assert os.readlink(fs.join(view, "sub/movie.mp4")) == "../../vd2/movie.mp4"
assert not fs.lexists(fs.join(view, "sub/rel"))
print("R ok", [n for n in fm.notes])
# collision: a different file already named movie.mp4 in a link dir
os.unlink(fs.join(view, "movie.mp4"))
os.unlink(fs.join(view, "sub/movie.mp4"))
os.rename(new, real)
links()
w(fs.join(view, "movie.mp4"))
fm, text = full_cycle("R", d2)
assert any("2 re-pointed in place" in n for n in fm.notes), fm.notes
assert (
    os.readlink(fs.join(view, "abs")) == new
    and fs.exists(fs.join(view, "abs"))
    and fs.exists(fs.join(view, "chain"))
), "old links must not stay dangling"
assert os.path.getsize(fs.join(view, "movie.mp4")) == 0 and not fs.islink(
    fs.join(view, "movie.mp4")
), "foreign file untouched"
os.unlink(fs.join(view, "movie.mp4"))
os.rename(new, real)
links()

# cancel with Enter and Esc: nothing moved, buffer cleared
for key in ("enter", "esc"):
    fm, text = full_cycle(None, d2, key=key)
    assert fm.copy_buffer == set() and not fm.do_cut and fs.exists(real), key
# n -> dashboard + cancel
fm = newfm(fs.join(d1, "a"))
fm.select(real)
fm.cut()
fm.console.answer("n")
assert fm.cds and fm.cds[-1].endswith("bnm/movie.mp4") and not fm.copy_buffer
# y -> moves, leaves links dangling
fm, text = full_cycle("y", d2)
assert os.readlink(fs.join(view, "abs")) == real and not fs.exists(fs.join(view, "abs"))
os.rename(new, real)
links()

# paste-time safety net: cut happened before the plugin knew (no policy) -> asks at paste
fm = newfm(fs.join(d1, "a"))
fm.select(real)
fm.copy_buffer = {Entry(real)}
fm.do_cut = True
fm.thistab.path = d2
fm.paste()
assert len(fm.console.q) == 1 and fm.queue == [] and "move?" in fm.console.q[0][0]
fm.console.answer("U")
fm.run_loader()
assert os.readlink(fs.join(view, "abs")) == new
os.rename(new, real)
links()
# nothing to warn about: no prompt, plain move
plain = fs.join(d1, "a/plain.mp4")
w(plain)
fm = newfm(fs.join(d1, "a"))
fm.select(plain)
fm.cut()
assert not fm.console.q and fm.do_cut
fm.thistab.path = d2
fm.paste()
fm.run_loader()
assert fs.exists(fs.join(d2, "plain.mp4"))
# outside the VD roots: only clips are checked
o = fs.join(outside, "x.mp4")
w(o)
w(fs.join(outside, "x_v3.mp4"))
os.symlink(o, fs.join(view, "to_out"))
fm = newfm(outside)
fm.select(o)
fm.cut()
text = fm.console.q[0][0]
assert "clip" in text and "symlink" not in text
fm.console.enter()
# a new cut resets stale policy: cut, answer U, cut something else (mode set), cut the first again => asked again
fm = newfm(fs.join(d1, "a"))
fm.select(real)
fm.cut()
fm.console.answer("U")
assert M._STATE.policy
fm.select(plain.replace("plain", "other"))
w(plain.replace("plain", "other"))
fm.cut()
assert not M._STATE.policy.get(real)
fm.select(real)
fm.cut()
assert len(fm.console.q) == 1
fm.console.enter()
# cancelled mover: partial result is reconciled (file not moved => links left alone, reported)
fm = newfm(fs.join(d1, "a"))
fm.select(real)
fm.cut()
fm.console.answer("U")
fm.thistab.path = d2
fm.paste()
gen = fm.queue[0].load_generator
fm.queue.clear()
gen.close()  # never started: nothing happens
assert os.readlink(fs.join(view, "abs")) == real
fm.queue and None
print("moves ok")

# ---------- directory move: links into the tree follow it
tree = fs.join(d1, "tree")
w(fs.join(tree, "in/f.mp4"))
os.symlink(fs.join(tree, "in/f.mp4"), fs.join(view, "into_tree"))
os.symlink(tree, fs.join(view, "tree_link"))
fm = newfm(d1)
fm.select(tree)
fm.cut()
text = fm.console.q[0][0]
print(text)
assert "2 symlink(s)" in text
fm.console.answer("U")
fm.thistab.path = d2
fm.paste()
fm.run_loader()
assert os.readlink(fs.join(view, "into_tree")) == fs.join(
    d2, "tree/in/f.mp4"
) and os.readlink(fs.join(view, "tree_link")) == fs.join(d2, "tree")
print("tree ok")

# ---------- :rename
src = fs.join(d1, "a/clipme.mp4")
w(src)
os.symlink(src, fs.join(view, "cl_abs"))
os.symlink("../vd1/a/clipme.mp4", fs.join(view, "cl_rel"))
os.chdir(fs.join(d1, "a"))


def do_rename(name, answers):
    fm = newfm(fs.join(d1, "a"))
    fm.select(fs.join(d1, "a/" + fs.basename(src_cur[0])))
    M.Command.fm = fm
    r = M.rename("rename " + name)
    r.execute()
    for a in answers:
        fm.console.answer(a)
    return fm


src_cur = [src]
fm = do_rename("renamed.mp4", ["U"])
assert fs.exists(fs.join(d1, "a/renamed.mp4"))
assert (
    os.readlink(fs.join(view, "cl_abs")) == fs.join(d1, "a/renamed.mp4")
    and os.readlink(fs.join(view, "cl_rel")) == "../vd1/a/renamed.mp4"
)
src_cur[0] = fs.join(d1, "a/renamed.mp4")
fm = do_rename("again.mp4", ["R"])
assert (
    fs.exists(fs.join(d1, "a/again.mp4"))
    and fs.islink(fs.join(view, "again.mp4"))
    and not fs.lexists(fs.join(view, "cl_abs"))
)
src_cur[0] = fs.join(d1, "a/again.mp4")
fm = newfm(fs.join(d1, "a"))
fm.select(src_cur[0])
M.Command.fm = fm
r = M.rename("rename nope.mp4")
r.execute()
fm.console.esc()
assert fs.exists(src_cur[0]) and not fs.exists(fs.join(d1, "a/nope.mp4"))
w(fs.join(d1, "a/free.mp4"))
fm = newfm(fs.join(d1, "a"))
fm.select(fs.join(d1, "a/free.mp4"))
M.Command.fm = fm
r = M.rename("rename free2.mp4")
r.execute()
assert not fm.console.q and fs.exists(fs.join(d1, "a/free2.mp4"))
print("rename ok")

# ---------- guards don't hang when the cache lock is busy (warm-up running)
M.LOCK_WAIT = 0.05
hold = threading.Event()
release = threading.Event()


def holder():
    with M._cache.lock:
        hold.set()
        release.wait(5)


t = threading.Thread(target=holder)
t.start()
hold.wait()
fm = newfm(fs.join(d1, "a"))
fm.select(src_cur[0])
M.Command.fm = fm
fm.thisfile = fm.sel[0]
M.delete("delete").execute()
fm.console.answer("y")
text = fm.console.q[0][0]
print(text)
assert "unavailable" in text
fm.console.esc()
assert fm.deleted == []
fm.cut()
assert "unavailable" in fm.console.q[0][0]
fm.console.enter()
assert not fm.copy_buffer
release.set()
t.join()
print("OK3")
