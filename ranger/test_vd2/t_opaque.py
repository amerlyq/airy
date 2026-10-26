from ranger.core.actions import Actions

from harness import *

_o = Actions.paste


def paste(self, *a, **k):
    return _o(self, *a, **k)  # a clipboard-style wrapper, no functools.wraps


Actions.paste = paste
import pasteflow

root = tempfile.mkdtemp()
src = os.path.join(root, "src")
dst = os.path.join(root, "dst")
oth = os.path.join(root, "oth")
for d in (src, dst, oth):
    os.makedirs(d)
for n in ("b.txt", "a.txt"):
    open(os.path.join(src, n), "w").write(n)
for n in ("a0", "zz"):
    open(os.path.join(dst, n), "w").write("o")
fm = make_fm(src)


def goto(p):
    d = fm.get_directory(p)
    d.load_content(schedule=False)
    fm.thistab.thisdir = d
    fm.thistab.pathway = (d,)
    fm.thistab.path = p
    return d


sd = goto(src)
ok = lambda c, m: print(("PASS " if c else "FAIL ") + m)
cur = lambda: fm.thisdir.files[fm.thisdir.pointer].basename
# opaque wrapper: still jumps
dd = goto(dst)
dd.move_to_obj(os.path.join(dst, "zz"))
fm.copy_buffer = {f for f in sd.files_all}
fm.do_cut = False
fm.paste()
pump(fm)
ok(cur() == "a.txt", "opaque wrapper in front: jump works -> " + cur())
# :mvsel style: cut in src, paste(dest=oth): no jump by default (cursor stays in src), follow=cd+jump
for follow in (False, True):
    for n in os.listdir(oth):
        os.remove(os.path.join(oth, n))
    for n in ("b.txt", "a.txt"):
        open(os.path.join(src, n), "w").write(n)
    sd = goto(src)
    sd.load_content(schedule=False)
    fm.copy_buffer = {f for f in sd.files_all}
    fm.do_cut = True
    kw = {"jump": "follow"} if follow else {}
    fm.paste(dest=oth, **kw)
    pump(fm)
    ok(
        (fm.thisdir.path == oth and cur() == "a.txt")
        if follow
        else fm.thisdir.path == src,
        f"mvsel-like follow={follow}: dir={os.path.basename(fm.thisdir.path)}",
    )
# retry path: stale listing (dir loaded & cached before files exist, load already pending)
dd = goto(dst)
os.remove(os.path.join(dst, "a.txt"))
dd.load_content(schedule=False)
fm.copy_buffer = {f for f in goto(src).files_all} if False else set()
open(os.path.join(src, "n.txt"), "w").write("n")
sd = goto(src)
sd.load_content(schedule=False)
fm.copy_buffer = {f for f in sd.files_all if f.basename == "n.txt"}
fm.do_cut = False
goto(dst)
pasteflow.JUMP_RETRIES = 3
orig_load = dd.load_content
calls = []


def stale_once(schedule=None):  # first reload after the paste returns the OLD listing
    calls.append(1)
    if len(calls) == 1:
        dd.files_all = [f for f in dd.files_all if f.basename != "n.txt"]
    return orig_load(schedule)


fm.paste()
pump(fm)
ok(cur() == "n.txt", "retry path -> " + cur())
