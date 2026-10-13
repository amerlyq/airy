"""vddangling: symlinks that start to dangle behind ranger's back (bulkrename, shell mv/rm...).

Nothing can hook those, so they are caught afterwards: every refreshing :vdsym compares the
links that dangle now with the previous check (PREFLIGHT hook of vdsym) and, failing that, a
ranger timer (rhooks.on_tick) repeats the comparison once after C.DANGLING_QUIET s without VD
activity.  Also :dangling [update].  State (_mon) survives a re-exec (rhooks.shared).
"""

from __future__ import annotations

import logging
import time
from collections.abc import Iterable
from os import path as fs

from ranger.api.commands import Command
from ranger.ext.shell_escape import shell_quote

try:  # ranger imports plugins as `plugins.<name>` with the confdir on sys.path
    from plugins import rhooks
    from plugins import vdconf as C
    from plugins import vdsym as _core
    from plugins.vdutil import (_brief, _dangling, _gone, _link_text,
                                _recovery, _safe_readlink, _swap_link)
except ImportError:  # fallback: the plugin files somewhere on PYTHONPATH
    import vdconf as C

    import rhooks
    import vdsym as _core
    from vdutil import (_brief, _dangling, _gone, _link_text, _recovery,
                        _safe_readlink, _swap_link)

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


def _dangling_now(wait: float) -> set[str] | None:
    """Every symlink under the VD roots that leads nowhere (None: cache busy for `wait` s)."""
    if not _core._cache.lock.acquire(timeout=wait):
        return None
    try:
        links = _core._cache.ensure(
            _core.vdsym.roots(), "validate", "links"
        ).index.links
        return {link for link in links if _dangling(link)}
    finally:
        _core._cache.lock.release()


def check_dangling(
    fm=None, notify: bool = True, wait: float = C.LOCK_WAIT
) -> list[str] | None:
    """Compare the dangling links with the previous check; log the new ones (details for
    :display_log) and notify shortly. The first check is the baseline. Returns the new links,
    or None when it could not run now (cache busy / ranger busy): nothing is lost, the next
    check simply compares against the older state."""
    mon = _mon
    if not C.DANGLING_MONITOR or (fm is not None and _busy(fm)):
        return None
    if not _core._cache.lock.acquire(timeout=wait):
        return None
    try:  # one step: snapshot + comparison (the lock is re-entrant)
        current = _dangling_now(wait)
        if current is None:
            return None
        previous, mon.known = mon.known, current
        mon.total = len(current)
    finally:
        _core._cache.lock.release()
    if previous is None:
        _LOG.info("vdsym: %d dangling symlink(s) at start", len(current))
        return []
    new = sorted(current - previous)
    if new:
        _LOG.warning(
            "%d symlink(s) newly dangling (%d in total):", len(new), len(current)
        )
        for link in new[:200]:
            _LOG.warning("  %s -> %s", link, _safe_readlink(link))
        if len(new) > 200:
            _LOG.warning("  ... and %d more", len(new) - 200)
        if notify and fm is not None:
            fm.notify(
                f"{len(new)} symlink(s) newly dangling -- see :display_log", bad=True
            )
    return new


def _arm(delay: float | None = None) -> None:
    """(Re)start the one-shot timer: it fires after `delay` s without further VD activity."""
    if C.DANGLING_MONITOR:
        _mon.deadline = time.monotonic() + (
            C.DANGLING_QUIET if delay is None else delay
        )


def _tick() -> None:
    """Ranger's only timer: its main loop calls Loader.work() at least every idle_delay (2 s)."""
    mon = _mon
    if mon.deadline is None or time.monotonic() < mon.deadline:
        return
    mon.deadline = None
    try:
        if check_dangling(rhooks.fm()) is None:
            _arm(5.0)  # ranger or the cache was busy: try again shortly
    except Exception:
        _LOG.exception("vdsym dangling check failed")


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
    """:dangling [update]

    Lists the symlinks under the VD roots that lead nowhere, each with the real files of the
    same basename (candidates). `update` re-points every link that has exactly one candidate,
    after asking.
    """

    def execute(self) -> None:
        fm, mode = self.fm, self.arg(1)
        if mode not in ("", "update"):
            return fm.notify("Syntax: dangling [update]", bad=True)
        current = _dangling_now(C.LOCK_WAIT)
        if current is None:
            return fm.notify("cache is busy (warming), try again in a moment", bad=True)
        links = sorted(current)
        if not links:
            return fm.notify("no dangling symlinks")
        if mode == "":
            return _list_dangling(fm, links)
        return fm.ui.console.ask(
            f"re-point the dangling links that have exactly one candidate ({len(links)} dangling)?"
            " (y / C=cancel)",
            lambda ans: ans in ("y", "Y") and _repoint_unique(fm, links),
            ("c", "C", "y", "Y"),
        )


# --------------------------------------------------------------------------- #
# registration
# --------------------------------------------------------------------------- #

_mon = rhooks.shared("vddangling.monitor", _Monitor)


def _preflight(cmd, flags, proceed) -> None:
    """Before :vdsym: compare dangling links with the previous check (when the cache is
    refreshed anyway), tell about new ones; Enter = continue, Esc = abort the command."""
    _arm()
    new = None
    if "N" not in flags and cmd._mode(flags) in ("validate", "rescan"):
        new = check_dangling(cmd.fm, notify=False)
    if not new:
        return proceed()

    def answer(ans: str) -> None:
        if ans == "q":
            return
        if ans == "l":
            _list_dangling(cmd.fm, new)
        elif ans == "U":
            _repoint_unique(cmd.fm, new)
        proceed()

    cmd.fm.ui.console.ask(
        f"{len(new)} symlink(s) newly dangling: {_brief(map(fs.basename, new))}"
        " (:display_log) -- Enter=continue / Esc=abort / l=list / U=re-point",
        answer,
        ("c", "q", "l", "U"),
    )


def _baseline() -> None:
    if _mon.known is None:
        check_dangling(None)  # baseline: what dangles already is not news


_core.hook("preflight", "vddangling", _preflight)
_core.hook("cd", "vddangling", lambda path: _arm())
_core.hook("warm", "vddangling", _baseline)
rhooks.on_tick("vddangling", _tick)
