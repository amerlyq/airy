"""vddangling: symlinks that start to dangle behind ranger's back (bulkrename, shell mv/rm...).

Nothing can hook those, so they are caught afterwards: every refreshing :vdsym compares the
links that dangle now with the previous check (PREFLIGHT hook of vdsym) and, failing that, a
ranger timer (rhooks.on_tick) repeats the comparison once after C.DANGLING_QUIET s without VD
activity.  Also :dangling [update].  State (_mon) survives a re-exec (rhooks.shared).
"""

from __future__ import annotations

import logging
import queue
import re
import threading
import time
import types
from collections.abc import Iterable
from os import path as fs

from ranger.api.commands import Command
from ranger.ext.shell_escape import shell_quote

try:  # ranger imports plugins as `plugins.<name>` with the confdir on sys.path
    from plugins import rhooks
    from plugins import vdconf as C
    from plugins import vdsym as _core
    from plugins.vdutil import (_dangling, _gone, _link_text, _recovery,
                                _safe_readlink, _swap_link)
except ImportError:  # fallback: the plugin files somewhere on PYTHONPATH
    import rhooks
    import vdconf as C
    import vdsym as _core
    from vdutil import (_dangling, _gone, _link_text, _recovery,
                        _safe_readlink, _swap_link)

try:
    from plugins.vdutil import fit_text, run_async
except ImportError:
    from vdutil import fit_text, run_async

_LOG = logging.getLogger("ranger.vdsym")

# --------------------------------------------------------------------------- #
# shared cache
# --------------------------------------------------------------------------- #


class _Monitor:
    """Dangling-symlink bookkeeping (see check_dangling)."""

    def __init__(self) -> None:
        self.known: set[str] | None = (
            None  # dangling at the previous check; None = no baseline yet
        )
        self.deadline: float | None = (
            None  # monotonic time of the pending one-shot check
        )
        self.total = 0
        self.running = False  # a background check is in flight
        self.outcome: tuple | None = None  # (result,) handed from that thread to _tick
        self.validated: float | None = (
            None  # monotonic time of the last stat-walk (None: never)
        )
        self.slow: dict[
            str, float
        ] = {}  # mountpoint -> monotonic time until which it is skipped
        self.remote_at: dict[
            str, float
        ] = {}  # mountpoint -> last check of its remote links


def _acknowledge(links: Iterable[str]) -> None:
    """The user knowingly leaves these links dangling ("y" at a prompt): not news later."""
    known = _mon.known
    if known is not None:
        known.update(links)


# --------------------------------------------------------------------------- #
# dangling symlinks (what can't be hooked is caught afterwards)
# --------------------------------------------------------------------------- #


def _busy(fm) -> bool:
    """ranger is copying / moving / deleting: links may dangle for a moment, check later."""
    loader = getattr(fm, "loader", None)
    return bool(loader and loader.has_work())


# --------------------------------------------------------------------------- #
# cheap, bounded discovery (never on the main thread, never unbounded)
#
# WHY the old check froze ranger for ~10 s: the timer ran ON the main thread, stat-walked every
# cached directory ("validate": slow on NFS) and then stat'ed every link target while holding
# the cache lock. Now:
#   - the periodic check runs in a daemon thread; only its result is handled by the tick
#   - it trusts the cached link index ("none"), a full stat-walk happens every
#     C.DANGLING_REVALIDATE s (also in that thread)
#   - links are stat'ed by C.DANGLING_WORKERS daemon threads within a time budget; a link that
#     does not answer in time is skipped and its mount is left alone for C.DANGLING_SLOW_SKIP s
#   - links whose target is on a remote fs (C.DANGLING_REMOTE_FS) are checked only every
#     C.DANGLING_REMOTE_EVERY s; :dangling checks everything
# TROUBLESHOOT: "stat stalled under <mount>" in :display_log = that mount was skipped for a while
# --------------------------------------------------------------------------- #

_MOUNTS = rhooks.shared(
    "vddangling.mounts", lambda: types.SimpleNamespace(at=-1e9, table=[])
)


def _mount_table() -> list[tuple[str, str]]:
    """(mountpoint, fstype), longest mountpoint first; re-read every minute."""
    now = time.monotonic()
    if now - _MOUNTS.at < 60 and _MOUNTS.table:
        return _MOUNTS.table
    rows: list[tuple[str, str]] = []
    try:
        with open("/proc/self/mountinfo", encoding="utf-8", errors="replace") as handle:
            for line in handle:
                left, _, right = line.partition(" - ")
                fields = left.split()
                if len(fields) > 4 and right:
                    mount = re.sub(
                        r"\\([0-7]{3})", lambda m: chr(int(m.group(1), 8)), fields[4]
                    )
                    rows.append((mount, right.split()[0]))
    except OSError:
        pass  # not Linux: everything counts as local
    rows.sort(key=lambda row: -len(row[0]))
    _MOUNTS.at, _MOUNTS.table = now, rows
    return rows


def _mount_of(path: str) -> tuple[str, str]:
    for mount, fstype in _mount_table():
        if path == mount or path.startswith(mount.rstrip("/") + "/"):
            return mount, fstype
    return "/", ""


def _target(link: str) -> str:
    raw = _safe_readlink(link)
    if raw is None:
        return link
    return fs.normpath(raw if fs.isabs(raw) else fs.join(fs.dirname(link), raw))


def _probe(links: list[str], budget: float) -> dict[str, bool]:
    """{link: is_dangling} for the links that answered within `budget` s (others: absent).
    Own daemon threads, not a ThreadPoolExecutor: its workers are joined at interpreter exit,
    so one hung NFS stat would hang ranger's exit."""
    out: dict[str, bool] = {}
    if not links:
        return out
    todo: queue.SimpleQueue[str] = queue.SimpleQueue()
    for link in links:
        todo.put(link)
    stop = threading.Event()

    def work() -> None:
        while not stop.is_set():
            try:
                link = todo.get_nowait()
            except queue.Empty:
                return
            out[link] = _dangling(link)

    threads = [
        threading.Thread(target=work, name="vddangling-stat", daemon=True)
        for _ in range(max(1, min(C.DANGLING_WORKERS, len(links))))
    ]
    for thread in threads:
        thread.start()
    deadline = time.monotonic() + budget
    for thread in threads:
        thread.join(max(0.0, deadline - time.monotonic()))
    stop.set()
    return dict(out)  # snapshot: late answers of hung threads must not change it


def _dash_dir() -> str:
    return fs.join(C.DASHBOARD_ROOT, C.DANGLING_DASHBOARD)


def _dashboard(links: list[str], fm=None, go: bool = False) -> str | None:
    """One symlink per dangling link under _dash_dir() (stale ones dropped); go: cd there."""
    try:
        return _core.make_dashboard(fm, links, _dash_dir(), go=go, track=False)
    except OSError as error:
        _LOG.warning("vdsym: dangling dashboard %s: %s", _dash_dir(), error)
        return None


def _compare(wait: float, budget: float, force: bool = False):
    """One bounded check -> (new, current, baseline) or None (cache busy for `wait` s).
    new: links that dangle now and did not at the previous check; current: all that dangle;
    baseline: this was the first check (new is empty). Links not answered in time keep their
    previous status. Builds the dashboard when something is new."""
    mon = _mon
    now = time.monotonic()
    due = mon.validated is None or now - mon.validated > C.DANGLING_REVALIDATE
    mode = "validate" if due else "none"
    if not _core._cache.lock.acquire(timeout=wait):
        return None
    try:  # the lock covers only the index, not the stats
        links = set(_core._cache.ensure(_core.vdsym.roots(), mode, "links").index.links)
    finally:
        _core._cache.lock.release()
    if mode == "validate":
        mon.validated = time.monotonic()
    skip = (
        C.DASHBOARD_ROOT.rstrip("/") + "/"
    )  # our own dashboard links lead to dangling links
    todo: list[str] = []
    where: dict[str, tuple[str, bool]] = {}
    for link in sorted(links):
        if link.startswith(skip):
            continue
        mount, fstype = _mount_of(_target(link))
        remote = fstype in C.DANGLING_REMOTE_FS
        if not force:
            if mon.slow.get(mount, 0.0) > now:
                continue
            if (
                remote
                and now - mon.remote_at.get(mount, -1e9) < C.DANGLING_REMOTE_EVERY
            ):
                continue
        todo.append(link)
        where[link] = (mount, remote)
    for mount, remote in set(where.values()):
        if remote:
            mon.remote_at[mount] = now
    answered = _probe(todo, budget)
    for mount in {where[link][0] for link in todo if link not in answered}:
        mon.slow[mount] = now + C.DANGLING_SLOW_SKIP
        _LOG.warning(
            "vdsym: stat stalled under %s; skipped for %d s",
            mount,
            C.DANGLING_SLOW_SKIP,
        )
    found = {link for link, bad in answered.items() if bad}
    previous = mon.known
    mon.known = (((previous or set()) & links) - set(answered)) | found
    mon.total = len(mon.known)
    current = sorted(mon.known)
    if previous is None:
        return [], current, True
    new = sorted(found - previous)
    if new:
        _dashboard(current)
    return new, current, False


def _report(fm, new: list[str], total: int) -> None:
    """Log the new links (details for :display_log) and tell where the dashboard is."""
    _LOG.warning("%d symlink(s) newly dangling (%d in total):", len(new), total)
    for link in new[:20]:
        _LOG.warning("  %s -> %s", link, _safe_readlink(link))
    if len(new) > 20:
        _LOG.warning("  ... and %d more", len(new) - 20)
    if fm is not None:
        fm.notify(
            f"{len(new)} symlink(s) newly dangling ({total} in total) -> {_dash_dir()}"
            "  (:dangling)",
            bad=True,
        )


def _open_dashboard(fm, links: list[str]) -> None:
    if _dashboard(links, fm, go=True) is None:
        fm.notify(f"cannot write {_dash_dir()}", bad=True)
    else:
        fm.notify(f"{len(links)} dangling symlink(s): follow one and fix it")


def check_dangling(
    fm=None,
    notify: bool = True,
    wait: float = C.LOCK_WAIT,
    budget: float | None = None,
) -> list[str] | None:
    """Compare the dangling links with the previous check (bounded, see _compare); log the new
    ones and, with notify, tell where the dashboard is. The first check is the baseline.
    Returns the new links, or None when it could not run now (cache busy / ranger busy):
    nothing is lost, the next check simply compares against the older state."""
    if not C.DANGLING_MONITOR or (fm is not None and _busy(fm)):
        return None
    result = _compare(wait, C.DANGLING_BUDGET if budget is None else budget)
    if result is None:
        return None
    new, current, baseline = result
    if baseline:
        _LOG.info("vdsym: %d dangling symlink(s) at start", len(current))
        return []
    if new:
        _report(fm if notify else None, new, len(current))
    return new


def _start() -> None:
    """Run one check in a daemon thread; _tick picks the outcome up on the main thread."""
    mon = _mon
    if mon.running:
        return
    mon.running = True

    def work() -> None:
        try:
            mon.outcome = (_compare(60.0, C.DANGLING_BUDGET),)
        except Exception:  # noqa: BLE001
            _LOG.exception("vdsym dangling check failed")
            mon.outcome = (None,)
        finally:
            mon.running = False

    threading.Thread(target=work, name="vddangling", daemon=True).start()


def _tick() -> None:
    """Ranger's only timer: its main loop calls Loader.work() at least every idle_delay (2 s).
    Cheap: hands over a finished check's outcome and, when due, starts the next one."""
    mon = _mon
    done, mon.outcome = mon.outcome, None
    if done is not None:
        if done[0] is None:
            _arm(5.0)  # cache was busy: try again shortly
        else:
            new, current, baseline = done[0]
            if baseline:
                _LOG.info("vdsym: %d dangling symlink(s) at start", len(current))
            elif new:
                _report(rhooks.fm(), new, len(current))
    if mon.deadline is None or time.monotonic() < mon.deadline:
        return
    mon.deadline = None
    fm = rhooks.fm()
    if mon.running or (fm is not None and _busy(fm)):
        return _arm(
            5.0
        )  # ranger is copying / moving, or the last check is still running
    _start()


## ALT: check on the main thread, stat-walking every cached dir ("validate") and stat'ing every link under the cache lock
##      benefit: one function, always complete, new links found at once; cost: froze ranger ~10 s on NFS roots
# def check_dangling(
#     fm=None, notify: bool = True, wait: float = C.LOCK_WAIT
# ) -> list[str] | None:
#     """Compare the dangling links with the previous check; log the new ones (details for
#     :display_log) and notify shortly. The first check is the baseline. Returns the new links,
#     or None when it could not run now (cache busy / ranger busy): nothing is lost, the next
#     check simply compares against the older state."""
#     mon = _mon
#     if not C.DANGLING_MONITOR or (fm is not None and _busy(fm)):
#         return None
#     if not _core._cache.lock.acquire(timeout=wait):
#         return None
#     try:  # one step: snapshot + comparison (the lock is re-entrant)
#         current = _dangling_now(wait)
#         if current is None:
#             return None
#         previous, mon.known = mon.known, current
#         mon.total = len(current)
#     finally:
#         _core._cache.lock.release()
#     if previous is None:
#         _LOG.info("vdsym: %d dangling symlink(s) at start", len(current))
#         return []
#     new = sorted(current - previous)
#     if new:
#         _LOG.warning(
#             "%d symlink(s) newly dangling (%d in total):", len(new), len(current)
#         )
#         for link in new[:200]:
#             _LOG.warning("  %s -> %s", link, _safe_readlink(link))
#         if len(new) > 200:
#             _LOG.warning("  ... and %d more", len(new) - 200)
#         if notify and fm is not None:
#             fm.notify(
#                 f"{len(new)} symlink(s) newly dangling -- see :display_log", bad=True
#             )
#     return new


def _arm(delay: float | None = None) -> None:
    """(Re)start the one-shot timer: it fires after `delay` s without further VD activity."""
    if C.DANGLING_MONITOR:
        _mon.deadline = time.monotonic() + (
            C.DANGLING_QUIET if delay is None else delay
        )


## ALT: (see above) previous timer tick and snapshot, verbatim
# def _tick() -> None:
#     """Ranger's only timer: its main loop calls Loader.work() at least every idle_delay (2 s)."""
#     mon = _mon
#     if mon.deadline is None or time.monotonic() < mon.deadline:
#         return
#     mon.deadline = None
#     try:
#         if check_dangling(rhooks.fm()) is None:
#             _arm(5.0)  # ranger or the cache was busy: try again shortly
#     except Exception:
#         _LOG.exception("vdsym dangling check failed")
# def _dangling_now(wait: float) -> set[str] | None:
#     """Every symlink under the VD roots that leads nowhere (None: cache busy for `wait` s)."""
#     if not _core._cache.lock.acquire(timeout=wait):
#         return None
#     try:
#         links = _core._cache.ensure(
#             _core.vdsym.roots(), "validate", "links"
#         ).index.links
#         return {link for link in links if _dangling(link)}
#     finally:
#         _core._cache.lock.release()


def _candidates(links: Iterable[str]) -> dict[str, list[str]]:
    """Real files (not links) with the basename a dangling link used to point at."""
    with _core._cache.lock:
        index = _core._cache.ensure(_core.vdsym.roots(), "none").index
        return {
            link: [
                path
                for path in index.names.get(
                    fs.basename((_safe_readlink(link) or "").rstrip("/")), ()
                )
                if path not in index.links and not _gone(path)
            ]
            for link in links
        }


def _repoint_unique(fm, links: Iterable[str]) -> None:
    """Re-point every link that has exactly one candidate to it."""
    todo = {
        link: found[0] for link, found in _candidates(links).items() if len(found) == 1
    }
    _recovery(
        "dangling-update",
        [f"{link} -> {candidate}" for link, candidate in todo.items()],
    )
    done = failed = 0
    for link, candidate in todo.items():
        try:
            _swap_link(
                link, _link_text(link, _safe_readlink(link) or "", candidate, "")
            )
            done += 1
        except OSError as error:
            failed += 1
            _LOG.warning("dangling update %s: %s", link, error)
    _core._cache.touch(todo)
    _mon.known = (_mon.known or set()) - set(todo)
    fm.notify(
        f"re-pointed {done} dangling link(s)"
        + (f", {failed} failed" if failed else ""),
        bad=bool(failed),
    )


def _list_dangling(fm, links: list[str]) -> None:
    lines = [f"{len(links)} dangling symlink(s):"]
    for link, found in _candidates(links).items():
        lines.append(f"{link} -> {_safe_readlink(link)}")
        lines += [f"    candidate: {path}" for path in found[:3]]
    fm.execute_command("printf '%s\\n' " + shell_quote("\n".join(lines)), flags="-w")


class dangling(Command):
    """:dangling [list|update]

    Opens the dashboard of the symlinks under the VD roots that lead nowhere: one link to each
    dangling link, so you can follow it and fix it. `list` prints them with the real files of
    the same basename (candidates). `update` re-points every link that has exactly one
    candidate, after asking. Checks everything (also remote targets) in the background.
    """

    def execute(self) -> None:
        fm, mode = self.fm, self.arg(1)
        if mode not in ("", "list", "update"):
            return fm.notify("Syntax: dangling [list|update]", bad=True)
        fm.notify("dangling: checking links ...")

        def work():
            result = _compare(60.0, 15.0, force=True)
            return None if result is None else result[1]

        def then(links) -> None:
            if links is None:
                return fm.notify(
                    "cache is busy (warming), try again in a moment", bad=True
                )
            if not links:
                return fm.notify("no dangling symlinks")
            if mode == "":
                return _open_dashboard(fm, links)
            if mode == "list":
                return _list_dangling(fm, links)
            fm.ui.console.ask(
                f"re-point the dangling links that have exactly one candidate ({len(links)} dangling)?"
                " (y / C=cancel)",
                lambda ans: ans in ("y", "Y") and _repoint_unique(fm, links),
                ("c", "C", "y", "Y"),
            )

        run_async(fm, work, then, "dangling")


## ALT: printed the list of dangling links
##      benefit: no dashboard to follow; use `:dangling list`
# class dangling(Command):
#     """:dangling [update]
#
#     Lists the symlinks under the VD roots that lead nowhere, each with the real files of the
#     same basename (candidates). `update` re-points every link that has exactly one candidate,
#     after asking.
#     """
#
#     def execute(self) -> None:
#         fm, mode = self.fm, self.arg(1)
#         if mode not in ("", "update"):
#             return fm.notify("Syntax: dangling [update]", bad=True)
#         current = _dangling_now(C.LOCK_WAIT)
#         if current is None:
#             return fm.notify("cache is busy (warming), try again in a moment", bad=True)
#         links = sorted(current)
#         if not links:
#             return fm.notify("no dangling symlinks")
#         if mode == "":
#             return _list_dangling(fm, links)
#         return fm.ui.console.ask(
#             f"re-point the dangling links that have exactly one candidate ({len(links)} dangling)?"
#             " (y / C=cancel)",
#             lambda ans: ans in ("y", "Y") and _repoint_unique(fm, links),
#             ("c", "C", "y", "Y"),
#         )


# --------------------------------------------------------------------------- #
# registration
# --------------------------------------------------------------------------- #

_mon = rhooks.shared("vddangling.monitor2", _Monitor)  # 2: new fields


def _preflight(cmd, flags, proceed) -> None:
    """Before :vdsym: compare dangling links with the previous check (when the cache is
    refreshed anyway; bounded by C.DANGLING_PREFLIGHT_BUDGET), tell about new ones;
    Enter = continue, Esc = abort the command, d = open the dashboard (and abort)."""
    _arm()
    new = None
    if "N" not in flags and cmd._mode(flags) in ("validate", "rescan"):
        new = check_dangling(cmd.fm, notify=False, budget=C.DANGLING_PREFLIGHT_BUDGET)
    if not new:
        return proceed()

    def answer(ans: str) -> None:
        if ans == "q":
            return
        if ans == "d":
            return _open_dashboard(cmd.fm, sorted(_mon.known or new))
        if ans == "l":
            _list_dangling(cmd.fm, new)
        elif ans == "U":
            _repoint_unique(cmd.fm, new)
        proceed()

    tail = " newly dangling -> dashboard -- Enter=continue / Esc=abort / d=open / l=list / U=re-point"
    short = " newly dangling -> dashboard (Enter/Esc/d/l/U)"
    if len(new) == 1:
        text = fit_text(cmd.fm, "symlink ", fs.basename(new[0]), tail, short)
    else:
        text = fit_text(cmd.fm, f"{len(new)} symlinks", "", tail, short)
    cmd.fm.ui.console.ask(text, answer, ("c", "q", "d", "l", "U"))


## ALT: listed up to 3 basenames in the prompt
##      benefit: names visible at a glance; cost: overflowed the screen
# def _preflight(cmd, flags, proceed) -> None:
#     """Before :vdsym: compare dangling links with the previous check (when the cache is
#     refreshed anyway), tell about new ones; Enter = continue, Esc = abort the command."""
#     _arm()
#     new = None
#     if "N" not in flags and cmd._mode(flags) in ("validate", "rescan"):
#         new = check_dangling(cmd.fm, notify=False)
#     if not new:
#         return proceed()
#
#     def answer(ans: str) -> None:
#         if ans == "q":
#             return
#         if ans == "l":
#             _list_dangling(cmd.fm, new)
#         elif ans == "U":
#             _repoint_unique(cmd.fm, new)
#         proceed()
#
#     cmd.fm.ui.console.ask(
#         f"{len(new)} symlink(s) newly dangling: {_brief(map(fs.basename, new))}"
#         " (:display_log) -- Enter=continue / Esc=abort / l=list / U=re-point",
#         answer,
#         ("c", "q", "l", "U"),
#     )


def _baseline() -> None:
    if _mon.known is None:
        check_dangling(None)  # baseline: what dangles already is not news


_core.hook("preflight", "vddangling", _preflight)
_core.hook("cd", "vddangling", lambda path: _arm())
_core.hook("warm", "vddangling", _baseline)
rhooks.on_tick("vddangling", _tick)
