from harness import *

root = tempfile.mkdtemp()
src = os.path.join(root, "src")
dst = os.path.join(root, "dst")
os.makedirs(src)
os.makedirs(dst)
for n in ("b.txt", "a.txt", "c.txt"):
    open(os.path.join(src, n), "w").write(n)
open(os.path.join(dst, "z0.txt"), "w").write("old")
open(os.path.join(dst, "a.txt"), "w").write("old")
fm = make_fm(dst)
d = fm.get_directory(dst)
d.load_content(schedule=False)
fm.thistab.thisdir = d
fm.thistab.pathway = (d,)
print("thisdir", fm.thisdir.path)
sd = fm.get_directory(src)
sd.load_content(schedule=False)
fm.copy_buffer = {f for f in sd.files_all if f.basename in ("a.txt", "b.txt")}
fm.do_cut = False
fm.paste()
pump(fm)
print(
    "files",
    sorted(os.listdir(dst)),
    "cursor",
    fm.thisdir.pointer,
    fm.thisdir.files[fm.thisdir.pointer].basename,
)
print("notes", fm.notes)
