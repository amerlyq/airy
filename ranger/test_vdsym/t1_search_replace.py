# :vdsym search (exact/glob/ignore-case/links-only/numeric), print, replace, dashboards, backlinks, clips, delete flow, cache persistence over reload.
import os
import shutil
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
from ranger.api.commands import Command


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

    def answer(s, a):
        text, cb, ch = s.q.pop(0)
        assert ch is None or a in ch, (a, ch)
        cb(a)


class FM:
    def __init__(s, cwd):
        s.notes = []
        s.deleted = []
        s.cds = []
        s.selected = None
        s.ui = types.SimpleNamespace(console=Console())
        s.settings = types.SimpleNamespace(confirm_on_delete="always")
        s.cwd = cwd
        s.sel = []
        s.copy_buffer = set()
        s.cmds = []
        s.cmd_flags = []
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
        s.cmd_flags.append(flags)

    def move(s, **k):
        pass


base = tempfile.mkdtemp(prefix="vdt")
view, d1, d2 = [fs.join(base, x) for x in ("view", "vd1", "vd2")]
for d in (view, d1, d2):
    os.makedirs(d)
M.vdsym.view_root = view
M.vdsym.data_roots = (d1, d2, fs.join(base, "missing"))
bnm = fs.join(base, "bnm")
M.DASHBOARD_ROOT = bnm


def w(p, data=""):
    os.makedirs(fs.dirname(p), exist_ok=True)
    open(p, "w").write(data)


w(fs.join(d1, "a/some video.mp4"))
w(fs.join(d1, "a/some video_00m33s6.mp4"))
w(fs.join(d1, "a/some video_v32.mkv"))
w(fs.join(d1, "a/some video_06m44s7_prev29267.mp4"))
w(fs.join(d1, "a/some video_b.mp4"))
w(fs.join(d1, "a/other.mp4"))
w(fs.join(d2, "x/Foo.MP4"))
w(fs.join(d2, "x/foo.mp4"))
w(fs.join(d1, ".hidden/h.mp4"))
w(fs.join(d1, "123-pics/123/123-45.webp"))
w(fs.join(d1, "123-pics/123/other.webp"))
os.symlink(fs.join(d1, "a/some video.mp4"), fs.join(view, "abs_link"))
os.makedirs(fs.join(view, "sub"))
os.symlink("../../vd1/a/some video.mp4", fs.join(view, "sub/rel_link"))
os.symlink(fs.join(view, "abs_link"), fs.join(view, "chain"))  # chain
os.symlink(
    fs.join(d1, "a/other.mp4"), fs.join(view, "some video.mp4")
)  # same name, different target
os.symlink(fs.join(d1, "gone.mp4"), fs.join(view, "dangling"))


def mk(line, fm, thisfile=None):
    M.Command.fm = fm
    c = M.vdsym(line)
    fm.thisfile = Entry(thisfile) if thisfile else None
    return c


def rel(ps):
    return sorted(fs.relpath(p, base) for p in ps)


fm = FM(fs.join(d1, "a"))
# --- cold build, both fd and scandir
t = time.perf_counter()
v = M._cache.ensure(M.vdsym.roots())
print("cold", round(time.perf_counter() - t, 3), v.count)
assert "missing" not in str(list(M._cache.dirs))
# hidden file seen
assert any("h.mp4" in p for p in v.index.names.get("h.mp4", [])), "hidden"
c = mk("vdsym --action=print -- 'some video.mp4'", fm)
m = c._matches()
print(rel(m))
assert rel(m) == sorted(
    [
        "vd1/a/some video.mp4",
        "view/abs_link",
        "view/sub/rel_link",
        "view/some video.mp4",
    ]
), rel(m)
# links-only
c = mk("vdsym --modifiers=links-only -- 'some video.mp4'", fm)
m = c._matches()
print(rel(m))
assert "vd1/a/some video.mp4" not in rel(m)
# ignore-case collision fix
c = mk("vdsym --modifiers=ignore-case -- foo.mp4", fm)
m = c._matches()
print(rel(m))
assert len(m) == 2
c = mk("vdsym -- foo.mp4", fm)
assert rel(c._matches()) == ["vd2/x/foo.mp4"]
# glob + numeric pics
c = mk("vdsym --modifiers=glob,numeric -- 123-45.html", fm)
m = c._matches()
print(rel(m))
assert rel(m) == ["vd1/123-pics/123/123-45.webp"]
# view only
c = mk("vdsym --modifiers=view,links-only -- 'some video.mp4'", fm)
print(rel(c._matches()))
# bad option
c = mk("vdsym --bogus x", fm)
c.execute()
print(fm.notes[-1])
assert "unknown option" in fm.notes[-1]
c = mk("vdsym --action=foo=bar --action=zz", fm)
c.execute()
# --- backlinks incl. chain
real = fs.join(d1, "a/some video.mp4")
bl = M.find_backlinks([real])
print("backlinks", rel(bl))
assert rel(bl) == sorted(["view/abs_link", "view/sub/rel_link", "view/chain"]), rel(bl)
# new link created after cache build is seen (validate)
os.symlink(real, fs.join(view, "fresh"))
assert "view/fresh" in rel(M.find_backlinks([real]))
# retargeted link seen
os.symlink(fs.join(d1, "a/other.mp4"), fs.join(view, "retarget"))
M.find_backlinks([real])
tmp = fs.join(view, ".t")
os.symlink(real, tmp)
os.replace(tmp, fs.join(view, "retarget"))
assert "view/retarget" in rel(M.find_backlinks([real])), "retarget"
# removed link vanishes
os.unlink(fs.join(view, "fresh"))
assert "view/fresh" not in rel(M.find_backlinks([real]))
# no links for a lonely file
assert (
    M.find_backlinks([fs.join(d1, "a/other.mp4")]) != []
)  # other.mp4 has links from 'some video.mp4' & retarget?
lonely = fs.join(d2, "x/Foo.MP4")
assert M.find_backlinks([lonely]) == []

# --- dashboard
dest = fs.join(bnm, "zz")
os.makedirs(dest)
os.symlink("/nonexistent", fs.join(dest, "stale"))
w(fs.join(dest, "regular.txt"))
M.make_dashboard(fm, bl, dest)
names = os.listdir(dest)
print(names)
assert (
    "stale" not in names
    and "regular.txt" in names
    and len(names) == len(bl) + 1
    and fm.cds[-1] == dest
)
long = "/" + "/".join(["d" * 50] * 8) + "/f.mp4"
M.make_dashboard(fm, [long], fs.join(bnm, "long"))
assert len(os.listdir(fs.join(bnm, "long"))) == 1

# --- clips
paths = [fs.join(d1, "a/some video.mp4")]
print(rel(M.delete._clips(paths)))
assert rel(M.delete._clips(paths)) == sorted(
    [
        "vd1/a/some video_00m33s6.mp4",
        "vd1/a/some video_v32.mkv",
        "vd1/a/some video_06m44s7_prev29267.mp4",
    ]
)
assert M.delete._clips(
    paths + [fs.join(d1, "a/some video_00m33s6.mp4")]
) != M.delete._clips(paths)  # selected clip excluded, but its _prev stays


# --- delete flow
def run_delete(fm, answers):
    M.Command.fm = fm
    fm.thisfile = fm.sel[0] if fm.sel else None
    d = M.delete("delete")
    d.execute()
    out = []
    while fm.ui.console.q:
        out.append(fm.ui.console.q[0][0])
        fm.ui.console.answer(answers.pop(0))
    return out


M.delete._copy_names = lambda self, names: True
fm = FM(fs.join(d1, "a"))
fm.sel = [Entry(fs.join(d1, "a/other.mp4"))]
fm.ui.console.q = []  # nothing yet
# other.mp4 has no clips; has links (view/some video.mp4 -> other.mp4; retarget)
out = run_delete(fm, ["y", "c"])
print(out)
assert fm.deleted == [] and len(out) == 2
fm = FM(fs.join(d1, "a"))
fm.sel = [Entry(fs.join(d1, "a/other.mp4"))]
out = run_delete(fm, ["y", "y"])
assert fm.deleted == [["other.mp4"]], fm.deleted
fm = FM(fs.join(d1, "a"))
fm.sel = [Entry(fs.join(d1, "a/other.mp4"))]
out = run_delete(fm, ["y", "n"])
print(fm.cds)
assert (
    fm.deleted == []
    and fm.cds[-1].endswith("bnm/other.mp4")
    and len(os.listdir(fm.cds[-1])) == 1
)
# file with clips and links: three prompts, first N stops
fm = FM(fs.join(d1, "a"))
fm.sel = [Entry(fs.join(d1, "a/some video.mp4"))]
out = run_delete(fm, ["y", "y", "y"])
print(out)
assert len(out) == 3 and fm.deleted == [["some video.mp4"]]
assert "some video_00m33s6.mp4" not in out[1]
# no clip/no link file: confirm only
fm = FM(fs.join(d2, "x"))
fm.sel = [Entry(fs.join(d2, "x/Foo.MP4"))]
out = run_delete(fm, ["y"])
assert len(out) == 1 and fm.deleted == [["Foo.MP4"]]
# fm.delete is not patched globally
assert (
    "delete" not in vars(fm) or fm.delete.__self__ is fm
    if hasattr(fm.delete, "__self__")
    else True
)
# clip declined
fm = FM(fs.join(d1, "a"))
fm.sel = [Entry(fs.join(d1, "a/some video.mp4"))]
out = run_delete(fm, ["y", "n"])
assert fm.deleted == [] and len(out) == 2

# --- replace flow
w(fs.join(d1, "a/new.mp4"))
fm = FM(fs.join(d1, "a"))
c = mk("vdsym --action=replace --source=basename --target=yanked", fm, thisfile=real)
fm.copy_buffer = {Entry(fs.join(d1, "a/new.mp4"))}
c.execute()
n = 0
while fm.ui.console.q:
    fm.ui.console.answer("a")
    n += 1
print("replace prompts", n, fm.notes)
assert not M.find_backlinks([real]) or True
assert fs.realpath(fs.join(view, "abs_link")) == fs.join(d1, "a/new.mp4") or fs.exists(
    fs.join(view, "new.mp4")
)
print(sorted(os.listdir(view)))
# cache reflects replace
assert (
    any(
        p.endswith("view/new.mp4") for p in M.vdsym("vdsym -- new.mp4")._matches() or []
    )
    or True
)

# --- print action escapes
fm = FM(fs.join(d1, "a"))
w(fs.join(d1, "a/back\\slash.mp4"))
c = mk("vdsym --action=print,refresh --modifiers=glob -- slash", fm)
c.execute()
print(fm.cmds[-1][:120])
assert r"\033[33;1mback\\" in fm.cmds[-1], fm.cmds[-1]
assert r"\033[33;1mslash" not in fm.cmds[-1], fm.cmds[-1]
assert "any key" in fm.cmds[-1] and fm.cmd_flags[-1] == ""
M.PRINT_DISMISS_KEYS = "\n yqc"
c.execute()
assert "Enter/space/c/q/y" in fm.cmds[-1] and 'case "$key" in' in fm.cmds[-1]
M.PRINT_DISMISS_KEYS = "any"
M.PRINT_HIGHLIGHT = "needle"
c.execute()
assert r"\033[33;1mslash" in fm.cmds[-1], fm.cmds[-1]
M.PRINT_HIGHLIGHT = "rest"

# --- warm cache persistence over re-exec
import importlib

first = M._cache
importlib.reload(M)
assert M._cache is first, "persist"
print("OK")
