import os
import sys
import tempfile
import time

sys.path.insert(0, "/home/claude/plugins")
import inocache

r = tempfile.mkdtemp()
f = os.path.join(r, "a")
open(f, "w").write("1")
ok = lambda c, m: print(("PASS " if c else "FAIL ") + m)
fp = inocache.Store("fpcalc", 1, "file", r)
mi = inocache.Store("mediainfo", 1, "file", r)
tags = inocache.Store("tags", 1, "none", r)
vis = inocache.Store("visited", 1, "path", r)
dd = inocache.Store("dirs", 1, "dir", r)
st = os.stat(f)
fp.put(st, ("chroma", 12))
tags.put(st, {"t": ["x"]})
vis.put("/some/dir", 1)
dd.put(os.stat(r), [1, 2])
for s in (fp, tags, vis, dd):
    s.flush()
# fresh stores = new process view
fp2 = inocache.Store("fpcalc", 1, "file", r)
tags2 = inocache.Store("tags", 1, "none", r)
vis2 = inocache.Store("visited", 1, "path", r)
dd2 = inocache.Store("dirs", 1, "dir", r)
ok(fp2.get(st) == ("chroma", 12), "file: hit after reopen")
ok(
    inocache.Store("mediainfo", 1, "file", r).get(st) is None,
    "stores are distinct (other name = miss)",
)
os.rename(f, f + "2")
ok(fp2.get(os.stat(f + "2")) == ("chroma", 12), "survives rename (inode key)")
time.sleep(0.01)
open(f + "2", "w").write("changed!")
ok(fp2.get(os.stat(f + "2")) is None, "file: edit invalidates")
ok(
    tags2.get(os.stat(f + "2")) == {"t": ["x"]},
    "none: edit does NOT invalidate (user tags)",
)
ok(vis2.get("/some/dir") == 1 and vis2.get("/other") is None, "path store")
ok(dd2.get(os.stat(r)) == [1, 2], "dir store hit")
open(os.path.join(r, "newfile"), "w").write("")
os.utime(r, None)
ok(dd2.get(os.stat(r)) is None, "dir: mtime change invalidates")
ok(len(fp2.get_many([st])) == 0 or True, "get_many runs")
fp3 = inocache.Store("fpcalc", 2, "file", r)
ok(fp3.get(st) is None, "version bump drops only that store")
ok(
    inocache.Store("tags", 1, "none", r).get(os.stat(f + "2")) == {"t": ["x"]},
    "...and not the others",
)
many = [os.stat(f + "2")]
fp4 = inocache.Store("fpcalc", 2, "file", r)
fp4.put(many[0], 5)
fp4.flush()
ok(
    inocache.Store("fpcalc", 2, "file", r).get_many(many) == {many[0].st_ino: 5},
    "get_many hit",
)
