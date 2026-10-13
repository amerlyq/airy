"""vdutil: plain filesystem / symlink helpers (no cache, no ranger state).

_safe_readlink _gone _dangling _norm _hops _brief   probing
_swap_link replace_link _link_text                    writing symlinks (atomic swap)
_recovery                                             append what is about to happen to RECOVERY_LOG
"""

from __future__ import annotations

import errno
import logging
import os
import time
from collections.abc import Iterable
from os import path as fs

try:
    from plugins import vdconf as C
except ImportError:
    import vdconf as C

_LOG = logging.getLogger("ranger.vdsym")


def _safe_readlink(path: str) -> str | None:
    try:
        return os.readlink(path)
    except OSError:
        return None


# --------------------------------------------------------------------------- #
# reusable helpers
# --------------------------------------------------------------------------- #


def _gone(path: str) -> bool:
    """Definitely not there (ENOENT / ENOTDIR). Unreadable or erroring paths count as present:
    a result is only dropped when we are sure it no longer exists."""
    try:
        os.lstat(path)
    except FileNotFoundError, NotADirectoryError:
        return True
    except OSError:
        return False
    return False


def _dangling(link: str) -> bool:
    """The link leads nowhere (or loops). Errors that say nothing about that (EACCES, EIO,
    a hung mount) are not 'dangling'."""
    try:
        os.stat(link)
    except FileNotFoundError, NotADirectoryError:
        return True
    except OSError as error:
        return error.errno == errno.ELOOP
    return False


def _norm(path: str) -> str:
    """Absolute path with parent directories resolved but the leaf kept (so a symlink stays itself)."""
    head, tail = fs.split(fs.abspath(path))
    return fs.join(fs.realpath(head), tail)


def _hops(link: str, limit: int = 40) -> Iterable[str]:
    """Successive targets of a symlink chain (each hop: parents resolved, leaf kept)."""
    current = link
    for _ in range(limit):
        if not fs.islink(current):
            return
        target = _safe_readlink(current)
        if target is None:
            return
        current = _norm(fs.join(fs.dirname(current), target))
        yield current


def _brief(items: Iterable[str], limit: int = 3) -> str:
    items = list(items)
    more = f" +{len(items) - limit}" if len(items) > limit else ""
    return " | ".join(items[:limit]) + more


# --------------------------------------------------------------------------- #
# writing symlinks
# --------------------------------------------------------------------------- #


def _swap_link(link: str, text: str, dest: str | None = None) -> None:
    """Atomically make `dest` (default: `link`) a symlink to `text`."""
    dest = dest or link
    temporary = fs.join(
        fs.dirname(link), f".{fs.basename(dest)[:200]}.vdsym-{os.getpid()}"
    )
    try:
        os.symlink(text, temporary)
        os.replace(temporary, dest)
    except OSError:
        if fs.lexists(temporary):
            os.unlink(temporary)
        raise


def replace_link(link: str, text: str, target: str) -> str | None:
    """Swap `link` for a link in the same dir named exactly like `target`, holding `text`.
    Returns an error message (collision / OS error) or None."""
    new_link = fs.join(fs.dirname(link), fs.basename(target))
    if new_link != link and fs.lexists(new_link):
        if not (fs.islink(new_link) and fs.realpath(new_link) == fs.realpath(target)):
            return f"Collision: {new_link}"
        try:
            os.unlink(link)  # an equivalent link is already there
        except OSError as error:
            return str(error)
        return None
    try:
        _swap_link(link, text, new_link)
        if new_link != link:
            os.unlink(link)
    except OSError as error:
        return str(error)
    return None


def _link_text(link: str, old_raw: str, new_raw: str, rest: str) -> str:
    """Target text for `link` once `old_raw` became `new_raw`: same style (absolute / relative),
    and the same spelling of the path when the old text was absolute."""
    raw = _safe_readlink(link) or ""
    new_abs = _norm(new_raw) + rest
    if fs.isabs(raw):
        text, old = fs.normpath(raw), fs.normpath(old_raw)
        if text == old or text.startswith(old + os.sep):
            return fs.normpath(new_raw) + text[len(old) :]
        return new_abs
    return fs.relpath(new_abs, fs.realpath(fs.dirname(link)))


def _recovery(op: str, lines: Iterable[str]) -> None:
    """Append what is about to happen, so a crash / cancel / error can be undone by hand."""
    try:
        os.makedirs(fs.dirname(C.RECOVERY_LOG), exist_ok=True)
        if fs.exists(C.RECOVERY_LOG) and fs.getsize(C.RECOVERY_LOG) > 2_000_000:
            os.replace(C.RECOVERY_LOG, C.RECOVERY_LOG + ".1")
        with open(
            C.RECOVERY_LOG, "a", encoding="utf-8", errors="surrogateescape"
        ) as handle:
            handle.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S')} {op}\n")
            for line in lines:
                handle.write(f"  {line}\n")
    except OSError:
        _LOG.warning("cannot write %s", C.RECOVERY_LOG)
