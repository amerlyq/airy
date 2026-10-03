"""Follow ranger selection in imv; follow imv navigation passively in ranger.

One controller belongs to each FM. Its input loop handles ranger input first,
then sends the final selection. Background polls carry an input generation;
results from before subsequent input are discarded. Back-sync never queues sends.
No compositor or tmux focus notifications are needed.

Track the newest imv socket created after ranger startup. This is discovery,
not process ownership: another application's newly launched imv is also eligible.
While tracking: i = tag_toggle, m = sync_imv_position, M = stop_imv_tracking.
M ignores existing sockets until another imv appears; original maps are restored.

Requires imv with shell-quoted `open` arguments (verified against imv 5.0.1).
Playlists contain visible image files in ranger order, captured when ranger
enters an image-containing directory and kept until a new list is sent.
Commands fit imv's 1023-byte receive buffer. IPC EOF acknowledges enqueueing;
an `exec printf` snapshot observes execution without relying on IPC replies.
"""

from __future__ import annotations

import curses
import mimetypes
import os
import shlex
import socket
import stat
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import NamedTuple

import ranger.api

IMV_POLL_MS = 300
IMV_DELAY_PRESETS_MS = [50, 100, 150, 200, 360, 420, 640, 800]
IMV_FORWARD_DELAYS_MS = [120, 400]
IMV_UP_DELAY_OVERRIDE_MS = 80
IMV_BURST_SIZE = 3  # <CASE: <=1 uses normal delay behavior.
IMV_BURST_BETWEEN_DELAY_MS = 700
IMV_HOLD_THRESHOLD_MS = 120
IPC_TIMEOUT = 0.15
IPC_MAX_BYTES = 1023
SOCKET_GLOB = "imv-*.sock"
TRACKING_MAPS = {
    "i": "tag_toggle",
    "I": "sync_imv_position",
    "m": "cycle_imv_forward_delay",
    "M": "stop_imv_tracking",
}


def _looks_like_image(path: str) -> bool:
    mime, _ = mimetypes.guess_type(path)
    return bool(mime and mime.startswith("image/")) or Path(path).suffix.lower() in {
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


class SocketInfo(NamedTuple):
    path: str
    device: int
    inode: int
    modified_ns: int


def _sockets() -> set[SocketInfo]:
    """Socket identity includes inode/mtime so a reused PID can be tracked again."""
    runtime = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    found = set()
    try:
        for path in Path(runtime).glob(SOCKET_GLOB):
            try:
                info = path.stat()
            except OSError:
                continue  # imv may exit during discovery
            if stat.S_ISSOCK(info.st_mode):
                found.add(
                    SocketInfo(str(path), info.st_dev, info.st_ino, info.st_mtime_ns)
                )
    except OSError:
        pass
    return found


def _send_command(sock_path: str, command: str) -> bool:
    """Wait for server EOF after half-close: prior commands are now enqueued."""
    payload = os.fsencode(command) + b"\n"
    if b"\0" in payload or len(payload) > IPC_MAX_BYTES:
        raise ValueError("imv command exceeds IPC limit or contains NUL")
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
            connection.settimeout(IPC_TIMEOUT)
            connection.connect(sock_path)
            connection.sendall(payload)
            connection.shutdown(socket.SHUT_WR)
            while connection.recv(4096):
                pass
        return True
    except OSError:
        return False


class Snapshot(NamedTuple):
    path: str
    index: int
    count: int


def _snapshot(sock: str) -> Snapshot | None:
    # A private directory prevents late execs from recreating an unlinked file
    # after timeout. NUL framing preserves newlines and whitespace in filenames.
    with tempfile.TemporaryDirectory(prefix="ranger-imv-") as directory:
        result = Path(directory) / "selection"
        command = (
            "exec printf '%s\\0%s\\0%s\\0' "
            '"$imv_current_file" "$imv_current_index" "$imv_file_count" > '
            + shlex.quote(str(result))
        )
        if not _send_command(sock, command):
            return None
        deadline = time.monotonic() + IPC_TIMEOUT
        while True:
            try:
                data = result.read_bytes()
            except FileNotFoundError:
                data = b""
            if data.endswith(b"\0") and data.count(b"\0") == 3:
                path, index, count, _ = data.split(b"\0")
                try:
                    return Snapshot(os.fsdecode(path), int(index), int(count))
                except ValueError:
                    return None
            if time.monotonic() >= deadline:
                return None
            time.sleep(0.005)


def _open_commands(paths: tuple[str, ...]) -> list[str]:
    """Quote before chunking; never split a path across imv commands."""
    commands = []
    command = "open"
    for path in paths:
        argument = " " + shlex.quote(path)
        if len(os.fsencode("open" + argument + "\n")) > IPC_MAX_BYTES:
            raise ValueError(f"Path too long for imv IPC: {path}")
        if len(os.fsencode(command + argument + "\n")) > IPC_MAX_BYTES:
            commands.append(command)
            command = "open"
        command += argument
    if command != "open":
        commands.append(command)
    return commands


class ImvSync:
    def __init__(self, fm):
        self.fm = fm
        self.ignored = _sockets()
        self.socket = None
        self.hunt_until = 0.0
        self.playlist = ()
        self.directory = ""
        self.playlist_tab = None
        self.last_tab = fm.thistab
        self.last_directory = getattr(fm.thisdir, "path", "")
        self.observed_selection = None
        self.forward_delay_index = 0
        self.forward_delays = list(IMV_FORWARD_DELAYS_MS)
        self.burst_size = IMV_BURST_SIZE
        self.burst_progress = 0
        self.last_forward_index = None
        self.last_forward_time = None
        self.held_steps = 0
        self.pending = False
        self.applying_snapshot = False
        self.last_poll = 0.0
        self.saved_maps = {}
        self.original_input = fm.ui.handle_input
        self.generation = 0
        self.snapshot_job = None
        self.executor = ThreadPoolExecutor(
            max_workers=1, thread_name_prefix="ranger-imv"
        )

    def install(self):
        self.fm.ui.handle_input = self.handle_input
        # Count actual input even when it causes no move (e.g. Down at EOF).
        # Both curses-buffered keys and unfocused mouse clicks reach these hooks.
        for name in ("handle_key", "handle_mouse"):
            original = getattr(self.fm.ui, name)

            def input_received(*args, _original=original, **kwargs):
                self.generation += 1
                return _original(*args, **kwargs)

            setattr(self.fm.ui, name, input_received)
        self.fm.signal_bind("move", self.on_move, priority=0, weak=False)
        self.fm.sync_imv_position = self.sync_from_imv
        self.fm.cycle_imv_forward_delay = self.cycle_forward_delay
        self.fm.stop_imv_tracking = self.stop
        self.fm.commands.load_commands_from_object(
            self.fm,
            [
                "sync_imv_position",
                "cycle_imv_forward_delay",
                "stop_imv_tracking",
            ],
        )
        original_after = self.fm.rifle.hook_after_executing

        def after_execution(*args, **kwargs):
            try:
                if original_after:
                    return original_after(*args, **kwargs)
            finally:
                self.hunt_until = time.monotonic() + 3  # imv socket not created yet
                self.discover()

        self.fm.rifle.hook_after_executing = after_execution

    def set_socket(self, selected):
        if selected == self.socket:
            return
        self.generation += 1
        self.socket = selected
        self.playlist = ()
        self.directory = getattr(self.fm.thisdir, "path", "")
        self.playlist_tab = self.fm.thistab
        self.observed_selection = None
        # self.pending = False
        self.pending = selected is not None  # new viewer: push ranger's playlist once
        self.last_poll = 0.0
        maps = self.fm.ui.keymaps
        if selected and not self.saved_maps:
            for key, command in TRACKING_MAPS.items():
                self.saved_maps[key] = maps["browser"].get(ord(key))
                maps.bind("browser", key, command)
        elif not selected and self.saved_maps:
            for key, original in self.saved_maps.items():
                # Do not overwrite a mapping the user changed while tracking.
                if maps["browser"].get(ord(key)) != TRACKING_MAPS[key]:
                    continue
                if original is None:
                    maps.unbind("browser", key)
                else:
                    maps.bind("browser", key, original)
            self.saved_maps.clear()

    def discover(self):
        current = _sockets()
        self.ignored.intersection_update(current)
        eligible = current - self.ignored
        self.set_socket(
            max(eligible, key=lambda item: (item.modified_ns, item.path), default=None)
        )

    def stop(self, narg=None, quantifier=None):
        count = narg if narg is not None else quantifier
        if count is not None:
            if 1 <= count <= 9:
                self.burst_size = count
                self.fm.notify(f"imv burst size: {count}")
            else:
                self.fm.notify("imv burst size must be 1..9", bad=True)
            return
        self.ignored.update(_sockets())
        self.set_socket(None)

    def cycle_forward_delay(self, narg=None, quantifier=None):
        count = narg if narg is not None else quantifier
        if count is None:
            self.forward_delay_index = 1 - self.forward_delay_index
            delay = self.forward_delays[self.forward_delay_index]
            self.fm.notify(f"imv forward delay: {delay} ms")
            return
        elif count <= len(IMV_DELAY_PRESETS_MS):
            source = count - 1
        elif count > 9:
            while len(IMV_DELAY_PRESETS_MS) < 9:
                IMV_DELAY_PRESETS_MS.append(0)
            IMV_DELAY_PRESETS_MS[8] = count
            source = 8
        else:
            self.fm.notify("imv delay slot unavailable", bad=True)
            return
        self.forward_delays[self.forward_delay_index] = IMV_DELAY_PRESETS_MS[source]
        self.fm.notify(
            f"imv forward delay {self.forward_delay_index + 1}: "
            f"{self.forward_delays[self.forward_delay_index]} ms"
        )

    def on_move(self, signal):
        if self.applying_snapshot:
            return
        if getattr(signal, "tab", self.fm.thistab) is not self.fm.thistab:
            return
        selected = os.path.realpath(getattr(self.fm.thisfile, "path", ""))
        if (
            self.observed_selection == selected
            and getattr(self.fm.thisdir, "path", "") == self.directory
            and self.fm.thistab is self.playlist_tab
        ):
            self.pending = False
            return
        self.generation += 1
        self.discover()
        # Store intent, not an index: input may emit multiple moves or sort
        # the directory before handle_input returns. Flush the final selection.
        self.pending = self.socket is not None

    def sync_to_imv(self):
        if not self.pending or not self.socket:
            return
        directory = self.fm.thisdir
        selected = getattr(self.fm.thisfile, "path", "")
        directory_path = directory.path
        entering = (
            self.fm.thistab is not self.playlist_tab or directory_path != self.directory
        )
        deleted = self.playlist and any(
            not os.path.exists(path) for path in self.playlist
        )
        rebuild = entering or not self.playlist or deleted
        if rebuild:
            self.last_forward_index = None
            self.last_forward_time = None
            self.held_steps = 0
            directory_files = getattr(directory, "files", None)
            if entering and directory_files is None:
                return
            paths = tuple(
                entry.path
                for entry in (directory_files or ())
                if not entry.is_directory and _looks_like_image(entry.path)
            )
            if paths or deleted:
                self.playlist = paths
        else:
            paths = self.playlist
        if selected not in paths:
            self.directory = directory_path
            self.playlist_tab = self.fm.thistab
            self.pending = False
            return
        rebuild = rebuild and bool(paths)
        index = paths.index(selected) + 1
        try:
            now = time.monotonic()
            continuous = (
                self.last_forward_time is not None
                and (now - self.last_forward_time) * 1000 <= IMV_HOLD_THRESHOLD_MS
            )
            if continuous:
                self.held_steps += 1
            else:
                self.held_steps = 0
                self.burst_progress = 0
            use_delay = continuous and self.held_steps >= 2
            if entering:
                self.burst_progress = 0
            if not use_delay:
                delay = 0
            elif self.burst_size > 1:
                delay = (
                    IMV_BURST_BETWEEN_DELAY_MS
                    if self.burst_progress == self.burst_size
                    else self.forward_delays[self.forward_delay_index]
                )
                self.burst_progress = (self.burst_progress + 1) % (self.burst_size + 1)
            else:
                delay = self.forward_delays[self.forward_delay_index]
            moving_up = (
                self.last_forward_index is not None and index < self.last_forward_index
            )
            if use_delay and moving_up and IMV_UP_DELAY_OVERRIDE_MS is not None:
                delay = IMV_UP_DELAY_OVERRIDE_MS
            imv_directory = (
                os.path.dirname(os.path.realpath(self.observed_selection))
                if self.observed_selection
                else None
            )
            if delay and imv_directory == os.path.realpath(directory_path):
                time.sleep(delay / 1000)
            elif imv_directory != os.path.realpath(directory_path):
                self.burst_progress = 0
            # Validate all commands before clearing the viewer's playlist.
            commands = ["close all", *_open_commands(paths)] if rebuild else []
            for command in commands:
                if not _send_command(self.socket.path, command):
                    self.playlist = ()  # Partial sends must be retried in full.
                    return
            if rebuild:
                snapshot = _snapshot(self.socket.path)
                if snapshot is None or snapshot.count != len(paths):
                    self.pending = False
                    return
            if not _send_command(self.socket.path, f"goto {index}"):
                self.playlist = ()
                return
        except ValueError as error:
            self.pending = False
            self.fm.notify(str(error), bad=True)
            return
        self.playlist = paths
        self.directory = directory_path
        self.playlist_tab = self.fm.thistab
        self.last_forward_index = index
        self.last_forward_time = time.monotonic()
        self.observed_selection = os.path.realpath(selected)
        self.pending = False

    def sync_from_imv(self):
        if not self.socket or self.pending or self.applying_snapshot:
            return
        context = (
            self.generation,
            self.socket,
            self.fm.thistab,
            getattr(self.fm.thisdir, "path", ""),
        )
        if self.snapshot_job is None:
            self.last_poll = time.monotonic()
            self.snapshot_job = (
                context,
                self.executor.submit(_snapshot, self.socket.path),
            )
        requested_context, future = self.snapshot_job
        if not future.done():
            return
        self.snapshot_job = None
        try:
            snapshot = future.result()
        except (OSError, ValueError):
            return  # Temporary-file/IPC failures are retried on the next poll.
        if requested_context != context or snapshot is None:
            return
        # imv can add images or reorder its own playlist while ranger's list
        # stays frozen. Invalidate only when the shown path leaves that list.
        if self.playlist and os.path.realpath(snapshot.path) not in {
            os.path.realpath(path) for path in self.playlist
        }:
            self.playlist = ()
        if not snapshot.path:
            return
        path = os.path.realpath(snapshot.path)
        selection = path
        if selection == self.observed_selection:
            return  # No new imv selection; preserve ranger's non-image moves.
        directory = self.fm.thisdir
        if (
            self.fm.thistab is not self.playlist_tab
            or getattr(directory, "path", "") != self.directory
        ):
            return
        files = getattr(directory, "files", None) or ()
        matches = [entry for entry in files if os.path.realpath(entry.path) == path]
        if not matches:
            return  # Never leave ranger's current visible directory.
        selected = matches[0]
        if self.playlist and 0 < snapshot.index <= len(self.playlist):
            indexed = self.playlist[snapshot.index - 1]
            selected = next(
                (entry for entry in matches if entry.path == indexed), selected
            )
        self.applying_snapshot = True
        try:
            # Avoid select_file's enter_dir: it can change filters and history.
            directory.move_to_obj(selected.path)
        finally:
            self.applying_snapshot = False
        self.observed_selection = selection

    def handle_input(self):
        self.discover()
        generation = self.generation
        # Ranger normally blocks up to idle_delay (often 2s). Temporarily cap
        # that wait while tracking so passive polling remains responsive.
        hunting = self.socket is None and time.monotonic() < self.hunt_until
        capped_wait = (self.socket is not None or hunting) and not self.fm.ui.load_mode
        if capped_wait:
            curses.halfdelay(1 if hunting else max(1, IMV_POLL_MS // 100))
        try:
            self.original_input()
        finally:
            if capped_wait and not self.fm.ui.load_mode:
                curses.halfdelay(min(255, max(1, self.fm.settings.idle_delay // 100)))
        if self.fm.thistab is not self.last_tab:
            self.last_tab = self.fm.thistab
            self.generation += 1
            self.pending = self.socket is not None
        current_directory = getattr(self.fm.thisdir, "path", "")
        if current_directory != self.last_directory:
            self.last_directory = current_directory
            self.generation += 1
            self.pending = self.socket is not None
        self.sync_to_imv()
        # A key waiting in curses is handled before any completed poll result.
        # Moves also invalidate queries issued before programmatic navigation.
        if (
            self.generation == generation
            and self.socket
            and (
                self.snapshot_job is not None
                or (time.monotonic() - self.last_poll) * 1000 >= IMV_POLL_MS
            )
        ):
            self.sync_from_imv()


_previous_hook_ready = ranger.api.hook_ready


def hook_ready(fm):
    if _previous_hook_ready:
        _previous_hook_ready(fm)
    if not hasattr(fm, "_imv_sync"):
        fm._imv_sync = ImvSync(fm)
        fm._imv_sync.install()


ranger.api.hook_ready = hook_ready
