import sys

sys.path.insert(0, "/tmp/t/conf")
import importlib
import threading

from harness import *

root = tempfile.mkdtemp()
data = os.path.join(root, "data")
view = os.path.join(root, "view")
sub = os.path.join(data, "sub")
for d in (data, view, sub):
    os.makedirs(d)
fm = make_fm(view)
fm.execute_command = lambda *a, **k: None
cds = []
fm.cd = lambda p, *a, **k: cds.append(p)
mods = {
    n: importlib.import_module("plugins." + n)
    for n in sorted(
        ["pasteflow", "rhooks", "vdconf", "vddangling", "vdguard", "vdsym", "vdutil"]
    )
}
vd, guard, dang, C, util = (
    mods[n] for n in ("vdsym", "vdguard", "vddangling", "vdconf", "vdutil")
)
vd.vdsym.data_roots = (data,)
vd.vdsym.view_root = view
C.DASHBOARD_ROOT = os.path.join(root, "dash")
C.RECOVERY_LOG = os.path.join(root, "rec.log")
C.WARM_ON_CD = False
con = fm.ui.console
ok = lambda c, m: print(("PASS " if c else "FAIL ") + m)


def mk(p):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    open(p, "w").write("x")
    return p


def goto(d):
    dd = fm.get_directory(d)
    dd.load_content(schedule=False)
    fm.thistab.thisdir = dd
    fm.thistab.pathway = (dd,)
    fm.thistab.path = d
    return dd


def pump2(n=3000):
    for _ in range(n):
        if not fm.loader.has_work():
            break
        fm.loader.work()


# ---- dd: immediate notice, async scan, one compact prompt -------------------------------- #
f = mk(os.path.join(data, "a_very_long_name_" + "x" * 90 + ".mp4"))
os.symlink(f, os.path.join(view, os.path.basename(f)))
d = goto(view)
d.move_to_obj(os.path.join(view, os.path.basename(f)))
# link pointing at the link we cut (a backlink to find)
os.symlink(
    os.path.join(view, os.path.basename(f)),
    os.path.join(view, "chain_" + "y" * 100 + ".mp4"),
)
con.answers[:] = ["U"]
t0 = time.time()
fm.cut()
t1 = time.time() - t0
ok(
    not con.asked and any("scanning" in n for n, _ in fm.notes),
    "dd returns at once with 'scanning' notice (asked=%d, %.3fs)"
    % (len(con.asked), t1),
)
pump2()
ok(len(con.asked) == 1, "one prompt after the background scan")
q = con.asked[0]
print("   prompt:", q, len(q))
ok(
    len(q) <= 79 and "\u2026" in q and q.startswith("symlink "),
    "single link: named, cut to screen width",
)

# ---- pp right after dd (before the scan finished) joins the same question ----------------- #
con.asked.clear()
guard._POLICY.clear()
guard._ANSWERED.clear()
fm.notes.clear()
d = goto(view)
d.move_to_obj(os.path.join(view, os.path.basename(f)))
con.answers[:] = ["U"]
fm.cut()
goto(sub)
fm.paste()  # buffer not answered yet
pump2()
pump2()
ok(len(con.asked) == 1, "dd + immediate pp: ONE prompt (asked=%d)" % len(con.asked))
ok(
    os.path.exists(os.path.join(sub, os.path.basename(f))),
    "paste ran after the single answer",
)

# ---- lost policy between dd and pp is not asked twice ---------------------------------------- #
con.asked.clear()
guard._POLICY.clear()
guard._ANSWERED.clear()
g = mk(os.path.join(data, "b.mp4"))
os.symlink(g, os.path.join(view, "b.mp4"))
os.symlink(os.path.join(view, "b.mp4"), os.path.join(view, "c1.mp4"))
os.symlink(os.path.join(view, "b.mp4"), os.path.join(view, "c2.mp4"))
d = goto(view)
d.move_to_obj(os.path.join(view, "b.mp4"))
con.answers[:] = ["U"]
fm.cut()
pump2()
ok(
    len(con.asked) == 1
    and "2 symlinks" in con.asked[0]
    and len(con.asked[0]) <= 79
    and "c1" not in con.asked[0],
    "several links: count only: " + con.asked[0][:40],
)
guard._on_reset(fm)  # something resets the buffer's bookkeeping between dd and pp
goto(sub)
fm.paste()
pump2()
ok(
    len(con.asked) == 1,
    "pp after a reset does not ask again (asked=%d)" % len(con.asked),
)

# ---- PROMPT_ON_CUT = False: asks only at paste ------------------------------------------------ #
C.PROMPT_ON_CUT = False
con.asked.clear()
guard._POLICY.clear()
guard._ANSWERED.clear()
h = mk(os.path.join(data, "h.mp4"))
os.symlink(h, os.path.join(view, "h.mp4"))
os.symlink(os.path.join(view, "h.mp4"), os.path.join(view, "hc.mp4"))
d = goto(view)
d.move_to_obj(os.path.join(view, "h.mp4"))
con.answers[:] = ["U"]
fm.cut()
pump2()
ok(not con.asked, "PROMPT_ON_CUT=False: no prompt at dd")
goto(sub)
fm.paste()
pump2()
ok(
    len(con.asked) == 1 and os.path.exists(os.path.join(sub, "h.mp4")),
    "...one prompt at pp, paste done",
)
C.PROMPT_ON_CUT = True

# ---- dangling: background check, dashboard, notification ------------------------------------------ #
for n in os.listdir(view):  # clean slate
    p = os.path.join(view, n)
    if os.path.islink(p):
        os.unlink(p)
os.symlink(f + "_gone", os.path.join(view, "ok_baseline"))
dang._mon.known = None
dang._mon.validated = None
dang._mon.slow.clear()
dang._mon.remote_at.clear()
r = dang.check_dangling(None)
ok(r == [], "baseline check silent")
os.symlink(os.path.join(data, "nope1"), os.path.join(view, "d1"))
os.symlink(os.path.join(data, "nope2"), os.path.join(view, "d2"))
vd._cache.ensure(
    vd.vdsym.roots(), "validate"
)  # index knows the new links (as after a refresh)
fm.notes.clear()
rhooks_fm = mods["rhooks"]._S
rhooks_fm.fm = fm
t0 = time.time()
dang._start()
ok(time.time() - t0 < 0.5, "background start returns at once")
for _ in range(200):
    dang._tick()
    if fm.notes:
        break
    time.sleep(0.02)
msg = fm.notes[-1][0] if fm.notes else ""
print("   notify:", msg)
dash = os.path.join(C.DASHBOARD_ROOT, C.DANGLING_DASHBOARD)
ok(
    "newly dangling" in msg and dash in msg and "/view/d" not in msg,
    "notification = count + dashboard path, no individual links",
)
ok(
    len(os.listdir(dash)) == 3
    and all(os.path.islink(os.path.join(dash, n)) for n in os.listdir(dash)),
    "dashboard has one link per dangling link: %d" % len(os.listdir(dash)),
)
vd._cache.ensure(vd.vdsym.roots(), "validate")
r2 = dang.check_dangling(None)
ok(r2 == [], "dashboard links are not counted as dangling themselves")

# ---- :dangling opens dashboard (async) ----------------------------------------------------------------- #
cds.clear()
c = dang.dangling("dangling")
c.fm = fm
c.execute()
pump2()
ok(cds and cds[-1] == dash, ":dangling cd -> dashboard")

# ---- bounded: one link hangs ------------------------------------------------------------------------------ #
orig = dang._dangling


def slow(link):
    if link.endswith("d2"):
        time.sleep(8)
    return orig(link)


dang._dangling = slow
dang._mon.known = set()
dang._mon.validated = time.monotonic()
dang._mon.slow.clear()
t0 = time.time()
res = dang._compare(5, 0.6)
el = time.time() - t0
ok(el < 2.0, "hung stat does not hold the check (%.2fs)" % el)
ok(
    any(v > time.monotonic() for v in dang._mon.slow.values()),
    "stalled mount is skipped for a while",
)
dang._dangling = orig

# ---- remote targets are throttled -------------------------------------------------------------------------- #
calls = []


def counting(link):
    calls.append(link)
    return orig(link)


dang._dangling = counting
dang._mon.slow.clear()
dang._mon.remote_at.clear()
dang._mon.known = set()
real_mount_of = dang._mount_of
dang._mount_of = lambda p: ("/mnt/nfs", "nfs")
dang._compare(5, 2)
n1 = len(calls)
dang._compare(5, 2)
n2 = len(calls)
ok(
    n1 > 0 and n2 == n1,
    "remote links probed once per DANGLING_REMOTE_EVERY (%d then +%d)" % (n1, n2 - n1),
)
dang._compare(5, 2, force=True)
ok(len(calls) > n2, "force (:dangling) ignores the throttle")
dang._mount_of = real_mount_of
dang._dangling = orig

# ---- preflight prompt is compact ------------------------------------------------------------------------------ #
con.asked.clear()
dang._mon.known = set()
dang._mon.slow.clear()
dang._mon.remote_at.clear()
dang._mon.validated = time.monotonic()
os.symlink(os.path.join(data, "nope3"), os.path.join(view, "d3_" + "z" * 100))
vd._cache.ensure(vd.vdsym.roots(), "validate")
con.answers[:] = ["q"]
cmd = vd.vdsym("vdsym -q x")
cmd.fm = fm
cmd.execute()
print("   preflight:", con.asked[-1] if con.asked else None)
ok(
    con.asked and len(con.asked[-1]) <= 79 and "dashboard" in con.asked[-1],
    "preflight prompt fits the screen and points at the dashboard",
)
