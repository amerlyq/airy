import sys

sys.path.insert(0, "/tmp/t/conf")
import importlib

from harness import *

# load like ranger: alphabetical, as plugins.<name>
fm = None
root = tempfile.mkdtemp()
data = os.path.join(root, "data")
view = os.path.join(root, "view")
other = os.path.join(root, "data2")
for d in (data, view, other, os.path.join(data, "sub")):
    os.makedirs(d)
fm = make_fm(data)
fm.execute_command = lambda *a, **k: None
fm.bookmarks = types.SimpleNamespace(update_path=lambda *a: None)
fm.tags.update_path = lambda *a: None
mods = {}
for name in sorted(
    ["pasteflow", "rhooks", "vdconf", "vddangling", "vdguard", "vdsym", "vdutil"]
):
    mods[name] = importlib.import_module("plugins." + name)
vd, guard, dang, C, pf = (
    mods["vdsym"],
    mods["vdguard"],
    mods["vddangling"],
    mods["vdconf"],
    mods["pasteflow"],
)
vd.vdsym.data_roots = (data, other)
vd.vdsym.view_root = view
C.DASHBOARD_ROOT = os.path.join(root, "dash")
C.RECOVERY_LOG = os.path.join(root, "rec.log")
C.WARM_ON_CD = False
ui = fm.ui
con = ui.console


def mk(path, text="x"):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    open(path, "w").write(text)
    return path


def load(d):
    dd = fm.get_directory(d)
    dd.load_content(schedule=False)
    return dd


def goto(d):
    dd = load(d)
    fm.thistab.thisdir = dd
    fm.thistab.pathway = (dd,)
    fm.thistab.path = dd.path
    return dd


def point(dd, name):
    dd.move_to_obj(os.path.join(dd.path, name))


def cur():
    return fm.thisdir.files[fm.thisdir.pointer].basename


ok = lambda c, m: print(("PASS " if c else "FAIL ") + m)

# ---- core cache + search --------------------------------------------------- #
f1 = mk(os.path.join(data, "x.mp4"), "video")
os.symlink("../data/x.mp4", os.path.join(view, "x.mp4"))
os.symlink(f1, os.path.join(view, "abs_x.mp4"))
vd._cache.ensure(vd.vdsym.roots(), "validate")
hits = vd.find_hits([f1])
ok(
    sorted(os.path.basename(h.link) for h in hits) == ["abs_x.mp4", "x.mp4"],
    "find_hits sees both links",
)
cmd = vd.vdsym("vdsym -n x.mp4")
cmd.fm = fm
ok(os.path.join(data, "x.mp4") in cmd._matches(), "vdsym _matches finds file")

# ---- :vdsym.execute preflight chain (dangling baseline then new dangling prompt) ---- #
sel = []
fm.select_file = lambda p: sel.append(p)
c1 = vd.vdsym("vdsym -b -q x.mp4")
c1.fm = fm  # -q only refreshes; first check = baseline, no prompt
c1.execute()
ok(not con.asked, "preflight: baseline silent")
os.symlink("../data/gone.mp4", os.path.join(view, "gone.mp4"))
c2 = vd.vdsym("vdsym -q x.mp4")
c2.fm = fm
con.answers[:] = ["c"]
c2.execute()
ok(
    con.asked and "newly dangling" in con.asked[-1],
    "preflight: new dangling link prompts",
)
con.asked.clear()
os.unlink(os.path.join(view, "gone.mp4"))
dang._mon.known = set()

# ---- guard: cut with prompt at cut time (U = update links), paste into sub ---- #
d = goto(data)
point(d, "x.mp4")
con.answers[:] = ["U"]
fm.cut()
ok(
    any("symlink(s)" in a and "cut?" in a for a in con.asked),
    "cut prompts about 2 symlinks",
)
ok(guard._POLICY.get(f1) == "U", "policy U remembered")
sub = os.path.join(data, "sub")
goto(sub)
fm.paste()
pump(fm)
new = os.path.join(sub, "x.mp4")
ok(os.path.exists(new) and not os.path.exists(f1), "file moved")
l = os.path.join(view, "x.mp4")
la = os.path.join(view, "abs_x.mp4")
ok(
    os.path.realpath(l) == os.path.realpath(new)
    and os.readlink(l) == "../data/sub/x.mp4",
    "relative link re-pointed: " + os.readlink(l),
)
ok(
    os.path.realpath(la) == os.path.realpath(new),
    "absolute link re-pointed: " + os.readlink(la),
)
ok(cur() == "x.mp4", "jump after guarded move")

# ---- guard: cancel at cut time unmarks ------------------------------------------ #
con.asked.clear()
d = goto(sub)
point(d, "x.mp4")
con.answers[:] = ["c"]
fm.cut()
ok(not fm.copy_buffer and not fm.do_cut, "cancel at cut empties buffer")

# ---- guard: cut WITHOUT hook prompt (buffer set directly) -> prompt at paste, R = replace ---- #
con.asked.clear()
guard._POLICY.clear()
d = goto(sub)
sd = load(sub)
fm.copy_buffer = {f for f in sd.files_all if f.basename == "x.mp4"}
fm.do_cut = True
con.answers[:] = ["R"]
tgt = goto(other)
fm.paste()
pump(fm)
ok(any("move?" in a for a in con.asked), "paste-time move prompt")
ok(os.path.exists(os.path.join(other, "x.mp4")), "moved to other root")
links = sorted(os.listdir(view))
print("   view after R:", links)
ok(
    all(
        os.path.realpath(os.path.join(view, n))
        == os.path.join(os.path.realpath(other), "x.mp4")
        for n in links
    ),
    "links follow (R)",
)

# ---- dup-link filtering: copy ---------------------------------------------------- #
tgtfile = mk(os.path.join(data, "t.bin"))
os.symlink(tgtfile, os.path.join(view, "dup"))
os.makedirs(os.path.join(root, "view2"))
os.symlink(tgtfile, os.path.join(root, "view2", "dup"))
vd2 = load(view)
fm.copy_buffer = {f for f in vd2.files_all if f.basename == "dup"}
fm.do_cut = False
goto(os.path.join(root, "view2"))
fm.notes.clear()
fm.paste()
pump(fm)
ok(
    any("same target" in n for n, _ in fm.notes)
    and sorted(os.listdir(os.path.join(root, "view2"))) == ["dup"],
    "copy skips duplicate link",
)

# ---- paste_symlink: dup + normal, with jump --------------------------------------- #
os.chdir(os.path.join(root, "view2"))
sd = load(data)
fm.copy_buffer = {f for f in sd.files_all if f.basename == "t.bin"}
fm.notes.clear()
fm.paste_symlink()
pump(fm)
ok(
    sorted(os.listdir(os.path.join(root, "view2"))) == ["dup", "t.bin"]
    and cur() == "t.bin",
    "paste_symlink creates + jumps",
)
fm.notes.clear()
fm.paste_symlink()
pump(fm)
ok(
    any("same target" in n for n, _ in fm.notes)
    and sorted(os.listdir(os.path.join(root, "view2"))) == ["dup", "t.bin"],
    "paste_symlink skips duplicate",
)

# ---- leave_symlink -------------------------------------------------------------- #
con.asked.clear()
guard._POLICY.clear()
a = mk(os.path.join(data, "ls.txt"))
d = goto(data)
fm.copy_buffer = {f for f in load(data).files_all if f.basename == "ls.txt"}
fm.do_cut = True
guard._POLICY[a] = "y"
goto(other)
fm.paste(leave_symlink=True)
pump(fm)
ok(
    os.path.islink(a) and os.path.exists(os.path.join(other, "ls.txt")),
    "leave_symlink: source link left: "
    + (os.readlink(a) if os.path.islink(a) else "-"),
)
fm.copy_buffer = {f for f in load(other).files_all if f.basename == "ls.txt"}
fm.do_cut = False
fm.notes.clear()
fm.paste(leave_symlink=True)
ok(any("requires cut" in n for n, _ in fm.notes), "leave_symlink needs cut")

# ---- dangling overwrite job ---------------------------------------------------- #
od = os.path.join(root, "ow")
os.makedirs(od)
os.symlink("nowhere", os.path.join(od, "q.txt"))
q = mk(os.path.join(data, "q.txt"), "real")
fm.copy_buffer = {f for f in load(data).files_all if f.basename == "q.txt"}
fm.do_cut = False
goto(od)
fm.paste(overwrite=True)
pump(fm)
ok(
    open(os.path.join(od, "q.txt")).read() == "real"
    and not os.path.islink(os.path.join(od, "q.txt"))
    and sorted(os.listdir(od)) == ["q.txt"],
    "overwrite over dangling link; no leftovers",
)

# ---- rename guard ------------------------------------------------------------------ #
ren = mk(os.path.join(data, "r.txt"))
os.symlink(ren, os.path.join(view, "r.txt"))
d = goto(data)
os.chdir(data)
point(d, "r.txt")
con.answers[:] = ["U"]
con.asked.clear()
rc = guard.rename("rename r2.txt")
rc.fm = fm
rc.execute()
pump(fm)
ok(
    os.path.exists(os.path.join(data, "r2.txt"))
    and os.path.realpath(os.path.join(view, "r.txt"))
    == os.path.realpath(os.path.join(data, "r2.txt")),
    "rename + re-point",
)

# ---- re-exec safety of everything ------------------------------------------------- #
for n in ("rhooks", "pasteflow", "vdguard", "vddangling", "vdsym"):
    importlib.reload(mods[n])
    importlib.reload(mods[n])
from ranger.core.actions import Actions

ok(
    Actions.paste.__wrapped__.__qualname__ == "Actions.paste",
    "single wrapper level after reloads",
)
ok(len(pf._REG["guard"]) == 3, "guards not duplicated: %s" % list(pf._REG["guard"]))
