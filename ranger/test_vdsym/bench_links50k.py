# Benchmark: cost of check_dangling() with 50k symlinks (runs on every refreshing :vdsym).
import os
import shutil
import sys
import tempfile
import time
import types
from os import path as fs

import vdsym as M

import paths  # noqa: F401

base = tempfile.mkdtemp(prefix="vdp3")
view, d1 = fs.join(base, "view"), fs.join(base, "vd")
M.vdsym.view_root = view
M.vdsym.data_roots = (d1,)
os.makedirs(view)
os.makedirs(d1)
for i in range(50000):
    os.symlink(fs.join(d1, f"f{i}.mp4") if i % 100 else "/gone", fs.join(view, f"l{i}"))
for i in range(0, 50000, 2):
    open(fs.join(d1, f"f{i}.mp4"), "w").close()
roots = M.vdsym.roots()
M._cache.ensure(roots)
time.sleep(2.2)
M._cache.ensure(roots, "validate")
t = time.perf_counter()
r = M.check_dangling(None)
print(
    "baseline check, 50k links:",
    round(time.perf_counter() - t, 3),
    len(M._cache.monitor.known),
)
t = time.perf_counter()
r = M.check_dangling(None)
print("repeat check, 50k links  :", round(time.perf_counter() - t, 3), r)
shutil.rmtree(base)
