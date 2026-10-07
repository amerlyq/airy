# R never leaves old links, inode-based relocation, existence filter, unreadable dirs, dangling check (piggy-back prompt, one-shot ranger timer via Loader.work), :dangling, links-only views.
import os
import sys
import tempfile
import threading
import time
import types
from os import path as fs

import paths  # noqa: F401  (plugin dir on sys.path, isolated state)
from harness import *

base = tempfile.mkdtemp(prefix="vdt4")
view, d1, d2, d3 = [fs.join(base, x) for x in ("view", "vd1", "vd2", "vd3")]
for d in (view, d1, d2, d3):
    os.makedirs(d)
M.vdsym.view_root = view
M.vdsym.data_roots = (d1, d2)
M.DASHBOARD_ROOT = fs.join(base, "bnm")
M.RECOVERY_LOG = fs.join(base, "state/moves.log")
M._cache.warmed = True
M.WARM_ON_CD = False


def w(p):
    os.makedirs(fs.dirname(p), exist_ok=True)
    open(p, "w").close()


def mk(line, fm, thisfile=None):
    M.Command.fm = fm
    c = M.vdsym(line)
    fm.thisfile = Entry(thisfile) if thisfile else None
    return c


def move(fm, srcs, dest, answer):
    fm.select(*srcs)
    fm.cut()
    while fm.console.q:
        fm.console.answer(answer)
    fm.thistab.path = dest
    fm.paste()
    fm.run_loader()


# ---- R: old links are always gone / never dangling; link already named like the file goes first
real = fs.join(d1, "a/movie.mp4")
w(real)
os.makedirs(fs.join(view, "g"))
os.symlink(real, fs.join(view, "zz_other"))
os.symlink(real, fs.join(view, "movie.mp4"))
os.symlink(fs.join(view, "zz_other"), fs.join(view, "zz_chain"))
os.symlink("../../vd1/a/movie.mp4", fs.join(view, "g/h"))
fm = newfm(fs.join(d1, "a"))
move(fm, [real], d2, "R")
new = fs.join(d2, "movie.mp4")
left = sorted(os.listdir(view))
print(left)
assert left == ["g", "movie.mp4"], left  # zz_other + zz_chain collapsed into movie.mp4
assert os.readlink(fs.join(view, "movie.mp4")) == new and os.listdir(
    fs.join(view, "g")
) == ["movie.mp4"]
assert not any(
    M._dangling(fs.join(view, x)) for x in ("movie.mp4",)
) and not M._dangling(fs.join(view, "g/movie.mp4"))
print("R ok:", fm.notes[-1])

# ---- U on a dashboard link, R leaves dashboard names alone (re-pointed in place)
os.rename(new, real)
for p in ("movie.mp4",):
    os.unlink(fs.join(view, p))
os.unlink(fs.join(view, "g/movie.mp4"))
os.symlink(real, fs.join(view, "v"))
os.makedirs(fs.join(base, "bnm/movie.mp4"))
os.symlink(real, fs.join(base, "bnm/movie.mp4/dash_link"))
fm = newfm(fs.join(d1, "a"))
move(fm, [real], d2, "R")
assert (
    os.readlink(fs.join(base, "bnm/movie.mp4/dash_link")) == new
    and fs.islink(fs.join(view, "movie.mp4"))
    and not fs.lexists(fs.join(view, "v"))
)
# the prompt itself never counted the dashboard link
os.rename(new, real)
os.unlink(fs.join(view, "movie.mp4"))
os.symlink(real, fs.join(view, "v"))
os.unlink(fs.join(base, "bnm/movie.mp4/dash_link"))
os.symlink(real, fs.join(base, "bnm/movie.mp4/dash_link"))
fm = newfm(fs.join(d1, "a"))
fm.select(real)
fm.cut()
assert fm.console.q[0][0].startswith("1 symlink(s)"), fm.console.q[0][0]
fm.console.enter()
os.unlink(fs.join(view, "v"))
os.unlink(fs.join(base, "bnm/movie.mp4/dash_link"))
print("dashboard ok")

# ---- two files with the same basename in one batch: both located, both links follow
x1, x2 = fs.join(d1, "p/same.mp4"), fs.join(d1, "q/same.mp4")
w(x1)
w(x2)
os.symlink(x1, fs.join(view, "l1"))
os.symlink(x2, fs.join(view, "l2"))
fm = newfm(fs.join(d1, "p"))
move(fm, [x1, x2], d2, "U")
dests = sorted(os.listdir(d2))
print(dests)
t1, t2 = os.readlink(fs.join(view, "l1")), os.readlink(fs.join(view, "l2"))
assert (
    t1 != t2
    and fs.exists(t1)
    and fs.exists(t2)
    and fs.dirname(t1) == d2 == fs.dirname(t2)
), (t1, t2)
print("batch ok")
# predicted name wrong (race: the name appeared after the guard looked) => found by inode
y = fs.join(d1, "p/race.mp4")
w(y)
os.symlink(y, fs.join(view, "lr"))
fm = newfm(fs.join(d1, "p"))
fm.select(y)
fm.cut()
fm.console.answer("U")
fm.thistab.path = d2
orig_paste_target = d2
fm.paste()  # job created with prediction d2/race.mp4
w(fs.join(d2, "race.mp4"))  # ... but somebody creates that name before the mover runs
fm.run_loader()
tgt = os.readlink(fs.join(view, "lr"))
print(tgt)
assert (
    tgt != fs.join(d2, "race.mp4")
    and fs.exists(tgt)
    and fs.basename(tgt).startswith("race.mp4_")
), tgt
print("inode ok")

# ---- existence filter: any size, only when the cache may be stale
for i in range(2300):
    w(fs.join(d2, "many", f"m{i}.txt"))
M._cache.ensure(M.vdsym.roots(), "validate")
for i in range(0, 2300, 2):
    os.unlink(fs.join(d2, "many", f"m{i}.txt"))
c = mk("vdsym --modifiers=glob,norefresh -- .txt", newfm(base))
got = c._matches()
assert len(got) == 1150 and all(fs.exists(p) for p in got), len(got)
c = mk("vdsym --modifiers=glob -- .txt", newfm(base))
got = c._matches()
assert len(got) == 1150  # validate: fresh, exact
c = mk("vdsym --modifiers=glob,norefresh -- .txt", newfm(base))
M._cache.ensure(M.vdsym.roots(), "none")
assert len(c._matches()) == 1150
# _gone: unreadable != gone
assert M._gone(fs.join(d2, "many", "m0.txt")) and not M._gone(
    fs.join(d2, "many", "m1.txt")
)
orig = os.lstat


def deny(p, *a, **k):
    if p.endswith("m1.txt"):
        raise PermissionError(13, "denied")
    return orig(p, *a, **k)


M.os.lstat = deny
assert not M._gone(fs.join(d2, "many", "m1.txt"))
M.os.lstat = orig
print("filter ok")

# ---- fd race: dirs touched after fd started are re-read; unreadable dirs are reported
rec = M._make_rec(fs.join(d2, "many"), d2, 1, [], since=0)
assert rec.racy
rec = M._make_rec(fs.join(d2, "many"), d2, 10**18, [], since=10**18 + 1)
assert not rec.racy or time.time_ns() - 10**18 < M.RACY_NS
old_scandir = os.scandir


def boom(p):
    if str(p).endswith("/vd2/locked"):
        raise PermissionError(13, "denied", p)
    return old_scandir(p)


os.makedirs(fs.join(d2, "locked"))
w(
    fs.join(d2, "locked/hidden_result.mp4")
)  # fresh => racy => re-read by the next validation
fm = newfm(base)
M._cache.unreadable.clear()
M._cache.reported_unreadable = frozenset()
M.os.scandir = boom
c = mk("vdsym -- same.mp4", fm)
c._matches()
M.os.scandir = old_scandir
assert fs.join(d2, "locked") in M._cache.unreadable and any(
    "unreadable" in n for n in fm.notes
), (M._cache.unreadable, fm.notes)
n_before = len(fm.notes)
M.os.scandir = boom
c = mk("vdsym -- same.mp4", fm)
c._matches()
M.os.scandir = old_scandir
assert len(fm.notes) == n_before, "reported once per change"
c = mk("vdsym -- hidden_result.mp4", fm)
got = c._matches()  # readable again: found and the warning is gone
assert [fs.basename(p) for p in got] == [
    "hidden_result.mp4"
] and not M._cache.unreadable, (got, M._cache.unreadable)
print("reliability ok")

# ---- dangling: compare at refresh time, short notification + details in the log, no threads
import logging

records = []


class Cap(logging.Handler):
    def emit(self, r):
        records.append(r.getMessage())


logging.getLogger("ranger.vdsym").addHandler(Cap())
logging.getLogger("ranger.vdsym").setLevel(logging.INFO)
M._cache.monitor = M._Monitor()
fm = newfm(base)
M._cache.fm = fm
fm.loader = types.SimpleNamespace(has_work=lambda: False)
tA, tB, tC = fs.join(d1, "m/a.mp4"), fs.join(d1, "m/b.mp4"), fs.join(d1, "m/c.mp4")
for t in (tA, tB, tC):
    w(t)
for n, t in (("ma", tA), ("mb", tB), ("mc", tC)):
    os.symlink(t, fs.join(view, n))
os.symlink("/nonexistent/old", fs.join(view, "already_dangling"))
assert (
    M.check_dangling(fm) == []
    and M._cache.monitor.known == {fs.join(view, "already_dangling")}
    and not fm.notes
)  # baseline: silent
assert M.check_dangling(fm) == [] and not fm.notes
os.unlink(tA)  # behind ranger's back
assert M.check_dangling(fm) == [fs.join(view, "ma")]
print(fm.notes[-1], records[-3:])
assert fm.notes[-1] == "1 symlink(s) newly dangling -- see :display_log"
assert any(r.strip() == f"{fs.join(view, 'ma')} -> {tA}" for r in records) and any(
    "newly dangling (2 in total)" in r for r in records
)
n = len(fm.notes)
assert M.check_dangling(fm) == [] and len(fm.notes) == n  # reported once
# ranger busy (paste in progress): not checked, nothing lost - the next check reports
os.unlink(tB)
fm.loader.has_work = lambda: True
assert M.check_dangling(fm) is None and len(fm.notes) == n
fm.loader.has_work = lambda: False
assert M.check_dangling(fm) == [fs.join(view, "mb")]
# cache busy: skipped, not an error
M.LOCK_WAIT = 0.05
hold, rel = threading.Event(), threading.Event()


def holder():
    with M._cache.lock:
        hold.set()
        rel.wait(5)


t = threading.Thread(target=holder)
t.start()
hold.wait()
assert M.check_dangling(fm, wait=0.05) is None
rel.set()
t.join()
# "y" at the delete prompt: the link is known to dangle
tD = fs.join(d1, "m/d.mp4")
w(tD)
os.symlink(tD, fs.join(view, "md"))
M.check_dangling(fm)
fm = newfm(fs.join(d1, "m"))
M._cache.fm = fm
fm.loader = types.SimpleNamespace(has_work=lambda: False)
fm.select(tD)
M.Command.fm = fm
M.delete._copy_names = lambda self, names: True
M.delete("delete").execute()
fm.console.answer("y")
fm.console.answer("y")
assert fm.deleted == [["d.mp4"]] and not fs.exists(tD)
assert M.check_dangling(fm) == [] and not any("newly" in x for x in fm.notes), fm.notes
# healed and dangling again => news again
w(tD)
assert M.check_dangling(fm) == []
os.unlink(tD)
assert M.check_dangling(fm) == [fs.join(view, "md")]
print("check ok")


# ---- the ranger timer: one-shot, after DANGLING_QUIET without VD activity, via Loader.work
class FakeLoader:
    calls = 0

    def work(self):
        FakeLoader.calls += 1


FakeLoader.work = M._make_work(FakeLoader.work)
ld = FakeLoader()
fm = newfm(base)
M._cache.fm = fm
fm.loader = types.SimpleNamespace(has_work=lambda: False)
M.check_dangling(fm)
os.symlink("/gone/for/good", fs.join(view, "late"))
mon = M._cache.monitor
mon.deadline = None
ld.work()
assert FakeLoader.calls == 1 and not any("late" in n for n in fm.notes), (
    "nothing armed => nothing happens"
)
M._arm()
ld.work()
assert mon.deadline and not fm.notes
n = len(fm.notes)
ld.work()
assert len(fm.notes) == n and mon.deadline, "not due yet"
mon.deadline = time.monotonic() - 1
ld.work()
assert (
    fm.notes[-1] == "1 symlink(s) newly dangling -- see :display_log"
    and mon.deadline is None
), fm.notes
n = len(fm.notes)
ld.work()
ld.work()
assert len(fm.notes) == n, "one shot"
# busy when due => re-armed shortly, not lost
os.symlink("/gone/too", fs.join(view, "late2"))
fm.loader.has_work = lambda: True
mon.deadline = time.monotonic() - 1
ld.work()
assert mon.deadline and mon.deadline - time.monotonic() <= 5.1
fm.loader.has_work = lambda: False
mon.deadline = time.monotonic() - 1
ld.work()
assert "newly dangling" in fm.notes[-1]
# VD activity postpones it
mon.deadline = None
M._on_cd(fs.join(d1, "m"))
assert mon.deadline and mon.deadline - time.monotonic() > M.DANGLING_QUIET - 1
print("timer ok")

# ---- :vdsym piggy-back: new dangling links are shown before the command runs
os.symlink(
    tA, fs.join(view, "ma2")
)  # already dangling at creation? (tA was deleted) -> new dangling link
fm = newfm(fs.join(d1, "m"))
M._cache.fm = fm
fm.loader = types.SimpleNamespace(has_work=lambda: False)
real_b = fs.join(d1, "m/uniq.mp4")
w(real_b)
os.symlink(real_b, fs.join(view, "mbb"))
LINE = "vdsym --action=autojump1,dashboard,jump --source=basename --modifiers=links-only --dashboard=/t/bnm"
c = mk(LINE, fm, thisfile=real_b)
c.execute()
text, cb, ch = fm.console.q[0]
print(text, ch)
assert (
    "newly dangling" in text
    and "ma2" in text
    and "Enter=continue / Esc=abort" in text
    and ch[:2] == ("c", "q")
    and fm.selected is None
)
fm.console.enter()
assert fm.selected and fm.selected.endswith("mbb"), (
    fm.selected
)  # Enter: continues with the real command
fm.selected = None
os.symlink("/also/gone", fs.join(view, "ma3"))
c = mk(LINE, fm, thisfile=real_b)
c.execute()
fm.console.esc()
assert fm.selected is None  # Esc: aborted
M._cache.monitor.known = M._dangling_now(1)  # accept current state
# norefresh skips the comparison entirely; no new links => no prompt
os.symlink("/and/gone", fs.join(view, "ma4"))
c = mk(LINE.replace("links-only", "links-only,norefresh"), fm, thisfile=real_b)
c.execute()
assert not fm.console.q and fm.selected.endswith("mbb")
c = mk(LINE, fm, thisfile=real_b)
fm.selected = None
c.execute()
assert fm.console.q
fm.console.q.clear()  # ma4 is news for the next refreshing run
# l lists with candidates, then continues
w(fs.join(d2, "moved/a.mp4"))
c = mk(LINE, fm, thisfile=real_b)
M._cache.monitor.known = M._dangling_now(1) - {fs.join(view, "ma2")}
fm.cmds.clear()
c.execute()
fm.console.answer("l")
out = fm.cmds[-1]
print(out)
assert "candidate: " + fs.join(d2, "moved/a.mp4") in out and fm.selected.endswith("mbb")
# U re-points the unique-candidate links and continues
fm.selected = None
M._cache.monitor.known = M._dangling_now(1) - {fs.join(view, "ma2")}
c = mk(LINE, fm, thisfile=real_b)
c.execute()
fm.console.answer("U")
assert (
    os.readlink(fs.join(view, "ma2")) == fs.join(d2, "moved/a.mp4")
    and fs.exists(fs.join(view, "ma2"))
    and fm.selected
), fm.notes
print("piggy-back ok")

# ---- :dangling
os.symlink(fs.join(d1, "m/c.mp4"), fs.join(view, "mc9"))
os.unlink(fs.join(d1, "m/c.mp4"))
w(fs.join(d2, "moved/c.mp4"))
fm.cmds.clear()
M.Command.fm = fm
M.dangling("dangling").execute()
out = fm.cmds[-1]
assert "candidate: " + fs.join(d2, "moved/c.mp4") in out and fs.join(view, "mc9") in out
M.dangling("dangling update").execute()
fm.console.esc()
assert not fs.exists(fs.join(view, "mc9"))  # Esc cancels
M.dangling("dangling update").execute()
fm.console.answer("y")
assert fs.exists(fs.join(view, "mc9")) and fs.realpath(fs.join(view, "mc9")) == fs.join(
    d2, "moved/c.mp4"
)
M.dangling("dangling bogus").execute()
assert "Syntax" in fm.notes[-1]
print("dangling cmd ok")

# ---- links-only views are small and separate; dashboards only on demand
v_all = M._cache.ensure(M.vdsym.roots(), "none")
v_links = M._cache.ensure(M.vdsym.roots(), "none", "links")
assert v_links.count < v_all.count and v_links.index.links
os.makedirs(fs.join(base, "bnm/x"))
os.symlink(tD + "2", fs.join(base, "bnm/x/dl"))
assert not any("bnm" in h.link for h in M.find_hits([tD + "2"])) and any(
    "bnm" in h.link for h in M.find_hits([tD + "2"], dashboards=True)
)
print("OK4")
