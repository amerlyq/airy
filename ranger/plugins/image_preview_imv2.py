"""
ranger imgfollow for imv — smooth navigation via index (no black blink)

What it does
- Watches ranger selection changes ("move" signal).
- Finds the newest imv UNIX socket in $XDG_RUNTIME_DIR (imv-*.sock).
- Builds ranger's *visible* image list (fm.thisdir.files) in current order.
- If the imv instance is new OR the visible list changed:
    - close all
    - open <many paths> (chunked, preserves order)
- Then, on every move:
    - goto <index> (1-based)

Why
- Avoids per-move `close all` which causes black flashes.
- Avoids spawning imv-msg processes; talks to the socket directly.
- No keymaps required.

Install
- Copy this file to: ~/.config/ranger/plugins/imgfollow_imv_index.py
- Restart ranger

Notes
- We send one command per socket connection/message (no ';' chaining).
- We try to send a *single* "open" command with many images, chunked to keep
  message size reasonable. Paths are quoted with double-quotes.

Tuning
- DEBOUNCE_MS: increase if you scroll fast.
"""

# pylint:disable=invalid-name,global-statement,using-constant-test,broad-exception-caught

from __future__ import annotations

import hashlib
import mimetypes
import os
import socket
import tempfile
import time
from collections.abc import Sequence
from pathlib import Path
from typing import TypedDict

import ranger.api  # for hook chaining
from ranger.core.fm import FM
from ranger.ext.keybinding_parser import parse_keybinding
from ranger.ext.signals import Signal

DEBOUNCE_MS = 60
IMV_POLL_MS = 300
SOCKET_GLOB = "imv-*.sock"

# If your build expects NUL-terminated commands instead of newline, set True:
SEND_NUL_TERMINATOR = False

# Keep each "open ..." payload under ~24 KiB by default (conservative)
OPEN_CMD_MAX_BYTES = 24 * 1024

# -------- internal state --------
_last_send_mono = 0.0
_last_path = ""
_orig_i_num = 0
_orig_i = ""
_changed_i = False
_changed_m = False
_orig_m = ""
_orig_handle_input = None
_wrapped_handle_input = False
_last_imv_poll_mono = 0.0
class ImvState(TypedDict):
    sock: str
    list_hash: int
    thisdir: str
    paths: tuple[str, ...]


_state: ImvState = {
    "sock": "",  # newest socket path
    "list_hash": 0,  # hash of visible image list
    "thisdir": "",
    "paths": tuple(),
}


def _xdg_runtime_dir() -> str:
    return os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}" or "/tmp"


def _looks_like_image(path: str) -> bool:
    mt, _ = mimetypes.guess_type(path)
    if mt and mt.startswith("image/"):
        return True
    ext = os.path.splitext(path)[1].lower()
    return ext in {
        ".png",
        ".jpg",
        ".jpeg",
        ".gif",
        ".webp",
        ".avif",
        ".heic",
        ".heif",
        ".tif",
        ".tiff",
        ".bmp",
        ".svg",
        ".qoi",
        ".jxl",
    }


def _newest_imv_socket() -> str | None:
    rt = _xdg_runtime_dir()
    try:
        entries = list(Path(rt).glob(SOCKET_GLOB))
    except Exception:
        return None
    if not entries:
        return None
    # newest by mtime
    entries.sort(key=lambda p: p.stat().st_mtime if p.exists() else 0.0)
    return str(entries[-1])


def _quote_imv(s: str) -> str:
    """Double-quote a path for imv's command parser."""
    s = s.replace("\x00", "?").replace("\n", "\\n").replace("\r", "\\r")
    s = s.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{s}"'


def _send_line(sock_path: str, line: str) -> bool:
    return _request(sock_path, line) is not None


def _request(sock_path: str, line: str) -> bytes | None:
    """Send an IPC command and return imv's reply, if any."""
    data = line.encode("utf-8", "surrogateescape")
    data += b"\x00" if SEND_NUL_TERMINATOR else b"\n"

    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.settimeout(0.10)
        s.connect(sock_path)
        s.sendall(data)
        reply = b""
        try:
            while True:
                chunk = s.recv(4096)
                if not chunk:
                    break
                reply += chunk
        except Exception:
            # A command which has no reply commonly times out here.
            pass
        return reply
    except Exception:
        return None
    finally:
        try:
            s.close()
        except Exception:
            pass


def _current_imv_path(sock: str) -> str | None:
    """Ask imv which file is selected, using a temp file for the result."""
    fd, result_path = tempfile.mkstemp(prefix="ranger-imv-", suffix=".path")
    os.close(fd)
    try:
        # imv's exec command runs inside imv; its stdout is not the IPC reply.
        command = f'exec echo "$imv_current_file" > {_quote_imv(result_path)}'
        if _request(sock, command) is None:
            return None

        # The exec is asynchronous, so allow a short handoff/write window.
        for _ in range(10):
            try:
                path = Path(result_path).read_text(
                    encoding="utf-8", errors="surrogateescape"
                ).strip()
            except OSError:
                path = ""
            if path:
                return path.splitlines()[-1].strip()
            time.sleep(0.02)
        return None
    finally:
        try:
            os.unlink(result_path)
        except OSError:
            pass


def _sync_from_imv_fm(fm: FM) -> None:
    """Follow imv's selected image in ranger."""
    # The compositor/tmux handoff can make the first request arrive too early.
    for delay in (0.0, 0.08, 0.20):
        if delay:
            time.sleep(delay)
        sock = _newest_imv_socket()
        if not sock:
            continue
        path = _current_imv_path(sock)
        if path and os.path.exists(path):
            fm.select_file(path)
            global _last_path
            _last_path = path
            return


def _poll_imv_before_input(fm: FM) -> None:
    global _last_imv_poll_mono
    now = time.monotonic()
    if (now - _last_imv_poll_mono) * 1000.0 < IMV_POLL_MS:
        return
    _last_imv_poll_mono = now
    _sync_from_imv_fm(fm)


def _set_imv_input_hooks(fm: FM, enabled: bool) -> None:
    """Temporarily follow imv while it exists, restoring ranger afterwards."""
    global _changed_m, _wrapped_handle_input
    if enabled and not _wrapped_handle_input:
        original = _orig_handle_input

        def handle_input_with_imv_sync():
            if _newest_imv_socket():
                _poll_imv_before_input(fm)
            else:
                _set_imv_input_hooks(fm, False)
            original()

        fm.ui.handle_input = handle_input_with_imv_sync
        _wrapped_handle_input = True
    elif not enabled and _wrapped_handle_input:
        fm.ui.handle_input = _orig_handle_input
        _wrapped_handle_input = False

    if enabled and not _changed_m:
        fm.ui.keymaps.bind("browser", "m", "sync_imv_position")
        _changed_m = True
    elif not enabled and _changed_m:
        if _orig_m is None:
            fm.ui.keymaps.unbind("browser", "m")
        else:
            fm.ui.keymaps.bind("browser", "m", _orig_m)
        _changed_m = False


def _hash_paths(paths: Sequence[str]) -> str:
    h = hashlib.sha1()
    for p in paths:
        h.update(p.encode("utf-8", "surrogateescape"))
        h.update(b"\x00")
    return h.hexdigest()


# def _sync_playlist(sock: str, paths: List[str]) -> None:
#     """Replace imv playlist with these paths, preserving order."""
#     _send_line(sock, "close all")
#     if not paths:
#         return
#
#     prefix = "open "
#     cur = prefix
#     cur_bytes = len(
#         (cur + ("\x00" if SEND_NUL_TERMINATOR else "\n")).encode(
#             "utf-8", "surrogateescape"
#         )
#     )
#
#     def flush(cmd: str) -> None:
#         if cmd.strip() != prefix.strip():
#             _send_line(sock, cmd.rstrip())
#
#     for p in paths:
#         qp = _quote_imv(p)
#         add = qp + " "
#         add_bytes = len(add.encode("utf-8", "surrogateescape"))
#         if cur_bytes + add_bytes > OPEN_CMD_MAX_BYTES and cur != prefix:
#             flush(cur)
#             cur = prefix
#             cur_bytes = len(
#                 (cur + ("\x00" if SEND_NUL_TERMINATOR else "\n")).encode(
#                     "utf-8", "surrogateescape"
#                 )
#             )
#         cur += add
#         cur_bytes += add_bytes
#
#     flush(cur)


def _sync_playlist(sock: str, paths: Sequence[str]) -> None:
    """Replace imv playlist with these paths, preserving order (one open per file)."""
    _send_line(sock, "close all")
    if not paths:
        return

    # One 'open' per file: most compatible, avoids multi-arg/quoting issues.
    for p in paths:
        _send_line(sock, f"open {p}")


def _ensure_synced(sock: str, fm: FM) -> int | None:
    dpath = getattr(fm.thisdir, "path", "")
    if not dpath:
        return None
    # PERF: preserve list until thisdir changes e.g. go up and back
    if _state["thisdir"] != dpath:
        paths = tuple(f.path for f in fm.thisdir.files if _looks_like_image(f.path))
        _state["paths"] = paths
        _state["thisdir"] = dpath
    else:
        paths = _state["paths"]

    # ALT:BAD: can't use (fm.thisdir.pointer + 1) COS we filter-out non-image files
    fpath = getattr(fm.thisfile, "path", "")
    if not fpath:
        return None
    idx = paths.index(fpath) + 1  # imv goto is 1-based

    # lh = _hash_paths(paths)
    lh = hash(paths)
    if _state["sock"] != sock or _state["list_hash"] != lh:
        if paths:
            _send_line(sock, "close all")
            _send_line(sock, f"open -r {dpath}")
            # _send_line(sock, "\n".join(f"open {p}" for p in paths))
            # BAD: it seems each open command is limited by 1024b
            # fm.notify(len(" ".join(paths[:19])))
            # _send_line(sock, "open " + " ".join(paths))
            # _sync_playlist(sock, paths)
            # FAIL:PERF too slow (loads like 5-10 pics / second)
            # for p in paths:
            #     _send_line(sock, f"open {p}")
        _state["sock"] = sock
        _state["list_hash"] = lh

    return idx


def _on_move(signal: Signal) -> None:
    global _last_send_mono, _last_path, _changed_i

    try:
        fm: FM = signal.origin
    except Exception:
        return

    # fm.notify("sljdslfjsdf", bad=True)

    # Debounce
    now = time.monotonic()
    if (now - _last_send_mono) * 1000.0 < DEBOUNCE_MS:
        return

    new = getattr(signal, "new", None)
    sel_path = getattr(new, "path", None) if new else None
    if not sel_path or not _looks_like_image(sel_path):
        return
    if _last_path == sel_path:
        return

    km = fm.ui.keymaps["browser"]

    # >OK
    # fm.notify(sel_path, bad=True)

    sock = _newest_imv_socket()
    if not sock:
        _set_imv_input_hooks(fm, False)
        if _changed_i and km.get(_orig_i_num) != _orig_i:
            fm.ui.keymaps.bind("browser", "i", _orig_i)
            _changed_i = False
        return

    _set_imv_input_hooks(fm, True)

    idx = _ensure_synced(sock, fm)
    if idx is None:
        return

    _send_line(sock, f"goto {idx}")

    if km.get("i") != "tag_toggle":
        fm.ui.keymaps.bind("browser", "i", "tag_toggle")
        _changed_i = True

        # map zi    chain set preview_images!;
        # eval cmd("map i tag_toggle" if fm.settings.preview_images else "map i display_file")

    _last_send_mono = now
    _last_path = sel_path


# ---- robust hook wiring (official pattern) ----
_HOOK_READY_OLD = ranger.api.hook_ready


def hook_ready(fm: FM) -> None:
    global _orig_i, _orig_m, _orig_handle_input
    _orig_i_num = tuple(parse_keybinding("i"))[0]
    _orig_i = fm.ui.keymaps["browser"].get(_orig_i_num)
    _orig_m = fm.ui.keymaps["browser"].get("m")
    _orig_handle_input = fm.ui.handle_input
    # fm.notify(_orig_i)

    # bind selection-change signal
    fm.signal_bind("move", _on_move, priority=0, weak=False)

    # Focus notifications are unreliable when ranger is nested in tmux/st.
    # Expose the same operation as :m while imv is active for manual testing.
    fm.sync_imv_position = lambda: _sync_from_imv_fm(fm)
    fm.commands.load_commands_from_object(fm, ["sync_imv_position"])

    # Also activate the input hook when ranger launches imv through rifle.
    old_rifle_after = fm.rifle.hook_after_executing

    def rifle_after(*args, **kwargs):
        if old_rifle_after:
            old_rifle_after(*args, **kwargs)
        _set_imv_input_hooks(fm, _newest_imv_socket() is not None)

    fm.rifle.hook_after_executing = rifle_after

    if _HOOK_READY_OLD:
        _HOOK_READY_OLD(fm)


ranger.api.hook_ready = hook_ready
