# -*- coding: utf-8 -*-
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
import time
from pathlib import Path
from typing import List, Optional, Tuple

import ranger.api  # for hook chaining
from ranger.core.fm import FM
from ranger.ext.keybinding_parser import KeyBuffer, parse_keybinding
from ranger.ext.signals import Signal

DEBOUNCE_MS = 60
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
_state = {
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


def _newest_imv_socket() -> Optional[str]:
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
    data = line.encode("utf-8", "surrogateescape")
    data += b"\x00" if SEND_NUL_TERMINATOR else b"\n"

    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    try:
        s.settimeout(0.10)
        s.connect(sock_path)
        s.sendall(data)
        # imv may or may not reply; don't block.
        try:
            s.recv(4096)
        except Exception:
            pass
        return True
    except Exception:
        return False
    finally:
        try:
            s.close()
        except Exception:
            pass


def _hash_paths(paths: List[str]) -> str:
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


def _sync_playlist(sock: str, paths: List[str]) -> None:
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
        if _changed_i and km.get(_orig_i_num) != _orig_i:
            fm.ui.keymaps.bind("browser", "i", _orig_i)
            _changed_i = False
        return

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
    global _orig_i
    _orig_i_num = tuple(parse_keybinding("i"))[0]
    _orig_i = fm.ui.keymaps["browser"].get(_orig_i_num)
    # fm.notify(_orig_i)

    # bind selection-change signal
    fm.signal_bind("move", _on_move, priority=0, weak=False)
    if _HOOK_READY_OLD:
        _HOOK_READY_OLD(fm)


ranger.api.hook_ready = hook_ready
