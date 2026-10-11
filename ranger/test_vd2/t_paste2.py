import pasteflow
from harness import *


def setup():
    root = tempfile.mkdtemp()
    src = os.path.join(root, "src")
    dst = os.path.join(root, "dst")
    os.makedirs(src)
    os.makedirs(dst)
    for n in ("b.txt", "a.txt", "c.txt"):
        open(os.path.join(src, n), "w").write(n)
    for n in ("a0", "m1", "zz"):
        open(os.path.join(dst, n), "w").write("old")
    fm = make_fm(dst)
    d = fm.get_directory(dst)
    d.load_content(schedule=False)
    fm.thistab.thisdir = d
    fm.thistab.pathway = (d,)
    sd = fm.get_directory(src)
    sd.load_content(schedule=False)
    return fm, d, sd, src, dst


def cur(fm):
    return fm.thisdir.files[fm.thisdir.pointer].basename


# 1 symlink: sync kind, jump to first new link in sort order
fm, d, sd, src, dst = setup()
fm.copy_buffer = {f for f in sd.files_all if f.basename in ("c.txt", "b.txt")}
os.chdir(dst)  # stock paste_symlink uses cwd for next_available_filename
fm.paste_symlink()
pump(fm)
print("symlink", sorted(os.listdir(dst)), "->", cur(fm))

# 2 relative kw passthrough
fm, d, sd, src, dst = setup()
os.chdir(dst)
fm.copy_buffer = {f for f in sd.files_all if f.basename == "c.txt"}
fm.paste_symlink(relative=True)
pump(fm)
print("rel", os.readlink(os.path.join(dst, "c.txt")), "->", cur(fm))

# 3 cut: move, jump
fm, d, sd, src, dst = setup()
fm.copy_buffer = {f for f in sd.files_all if f.basename in ("c.txt", "b.txt")}
fm.do_cut = True
fm.paste()
pump(fm)
print(
    "move",
    sorted(os.listdir(src)),
    sorted(os.listdir(dst)),
    "->",
    cur(fm),
    "buf",
    len(fm.copy_buffer),
)

# 4 jump=False and unknown opts
fm, d, sd, src, dst = setup()
fm.copy_buffer = {f for f in sd.files_all if f.basename == "c.txt"}
fm.paste(jump=False)
pump(fm)
print("nojump", cur(fm), fm.thisdir.pointer)

# 5 async guard: asks, answers later, drop one entry; and a guard that never proceeds (cancel)
fm, d, sd, src, dst = setup()
held = []


def g(p, proceed):
    p.drop([x for x in p.paths if x.endswith("a.txt")])
    held.append(proceed)


pasteflow.guard("t", g)
fm.copy_buffer = {f for f in sd.files_all if f.basename in ("a.txt", "b.txt")}
fm.paste()
pump(fm)
print("held: nothing yet", sorted(os.listdir(dst)))
held[0]()
held[0]()
pump(fm)
print(
    "after proceed (x2)",
    sorted(os.listdir(dst)),
    "->",
    cur(fm),
    "buffer",
    sorted(f.basename for f in fm.copy_buffer),
)


# 6 crashing guard aborts
def bad(p, proceed):
    raise RuntimeError("boom")


pasteflow.guard("t", bad)
fm.paste()
pump(fm)
print("crash notes", fm.notes[-1])
pasteflow._REG["guard"].clear()
# 7 overwrite: nothing new by name
fm, d, sd, src, dst = setup()
open(os.path.join(src, "m1"), "w").write("new")
sd.load_content(schedule=False)
fm.copy_buffer = {f for f in sd.files_all if f.basename == "m1"}
fm.paste(overwrite=True)
pump(fm)
print("overwrite", open(os.path.join(dst, "m1")).read(), "->", cur(fm))
# 8 empty buffer / bad dest don't crash
fm, d, sd, src, dst = setup()
fm.copy_buffer = set()
fm.paste()
pump(fm)
fm.copy_buffer = {f for f in sd.files_all}
fm.paste(dest="/nonexistent")
pump(fm)
print("bad dest notes", fm.notes)
# 9 re-exec safety: reload twice -> still ONE wrapper level
import importlib

importlib.reload(pasteflow)
importlib.reload(pasteflow)
from ranger.core.actions import Actions

print("wrapper depth", Actions.paste.__wrapped__.__qualname__)
