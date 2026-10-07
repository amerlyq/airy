# Benchmark: 80k files / 2.5k dirs: cold build (fd and scandir), validate, backlinks, glob + exact lookups.
import os
import shutil
import sys
import tempfile
import time
import types
from os import path as fs

import vdsym as M

import paths  # noqa: F401

base = tempfile.mkdtemp(prefix="vdp")
view, d1 = fs.join(base, "view"), fs.join(base, "vd")
M.vdsym.view_root = view
M.vdsym.data_roots = (d1,)
os.makedirs(view)
t = time.perf_counter()
n = 0
for i in range(2500):
    d = fs.join(d1, f"g{i % 50}", f"s{i}")
    os.makedirs(d)
    for j in range(32):
        open(fs.join(d, f"clip {i}-{j}.mp4"), "w").close()
        n += 1
for i in range(0, n // 40):
    os.symlink(fs.join(d1, f"g{(i * 40 // 32) % 50}", "x"), fs.join(view, f"l{i}"))
print("files", n, "setup", round(time.perf_counter() - t, 1))
# retarget some links to real files
target = fs.join(d1, "g0", "s0", "clip 0-0.mp4")
os.unlink(fs.join(view, "l0"))
os.symlink(target, fs.join(view, "l0"))
roots = M.vdsym.roots()
t = time.perf_counter()
v = M._cache.ensure(roots)
print("cold build (fd)", round(time.perf_counter() - t, 3), v.count)
time.sleep(2.5)
M._cache.ensure(
    roots, "validate"
)  # first pass after the racy window settles the records
t = time.perf_counter()
M._cache.ensure(roots, "validate")
print("validate (no change)", round(time.perf_counter() - t, 3))
t = time.perf_counter()
bl = M.find_backlinks([target])
print(
    "find_backlinks (validate+lookup)",
    round(time.perf_counter() - t, 3),
    [fs.basename(b) for b in bl],
)
os.symlink(target, fs.join(view, "newlink"))
t = time.perf_counter()
bl = M.find_backlinks([target])
print(
    "after new link",
    round(time.perf_counter() - t, 3),
    sorted(fs.basename(b) for b in bl),
)
t = time.perf_counter()
M._cache.ensure(roots, "rescan")
print("rescan (fd)", round(time.perf_counter() - t, 3))
# scandir fallback timing
M._cache.dirs.clear()
M._cache._fd = staticmethod(lambda r: None)
t = time.perf_counter()
M._cache.ensure(roots)
print("cold build (scandir fallback)", round(time.perf_counter() - t, 3))
# glob + ignore-case lookup
M.Command.fm = types.SimpleNamespace(thisfile=None)
c = M.vdsym("vdsym --modifiers=glob,ignore-case -- CLIP 7-1")
t = time.perf_counter()
m = c._matches()
print("glob lookup", round(time.perf_counter() - t, 3), len(m))
c = M.vdsym("vdsym -- 'clip 7-1.mp4'")
t = time.perf_counter()
m = c._matches()
print("exact lookup", round(time.perf_counter() - t, 3), len(m))
shutil.rmtree(base)
