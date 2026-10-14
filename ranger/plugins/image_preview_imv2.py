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
from functools import lru_cache
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
# OPTION: while imv tracking is active -- set ranger `preview_files=False`: no scope.sh
#   spawns, preview column collapses (more room for filenames), cached previews stay intact.
#   Restored when tracking ends. Manual `zp` (toggle_option preview_files) still works
#   while tracking, to verify that imv shows the same image as ranger.
# REQUIRES: ranger `set collapse_preview true` (default) for the column to collapse.
IMV_HIDE_PREVIEW = True
## ALT: env var RANGER_IMV_SYNC + `exit 1` for image/* in scope.sh -- still spawns scope.sh
##   per viewed image, caches "no preview" verdicts in fm.previews (needs clear to revert),
##   and blocks manual preview unconditionally.
# IMV_COLLAPSE_IMAGE_PREVIEW = True
# IMV_PREVIEW_ENV = "RANGER_IMV_SYNC"
# OPTION: keep animated webp out of the playlist (imv drops them => indexes shift).
#   Probing costs one 40-byte read per candidate, so only webp bigger than the threshold
#   are probed (cached by path+mtime). TRADEOFF: smaller animated webp are NOT detected
#   (-> use IMV_SYNC_MODE="name"). Set IMV_SKIP_ANIM=False to remove all probing cost.
IMV_SKIP_ANIM = True
IMV_ANIM_MIN_SIZE = 500_000  # bytes; sanity threshold, adjust to your animated/still split
# OPTION: how ranger selection is mapped to imv position
#   "index": goto <ranger index>; requires imv list == playlist (see _imv_can_show). 1 IPC.
#   "name":  goto <guess>, verify landed path via snapshot, shift guess, repeat. Tolerates
#            any files imv drops; costs >=1 extra snapshot round-trip per move (~5-15 ms).
IMV_SYNC_MODE = "index"
IMV_NAME_SYNC_STEPS = 4  # max goto+verify passes per move in "name" mode
# WHY: ANIM chunk sits at offset 30 (RIFF hdr 12 + VP8X chunk 18); keep in sync with rifle.conf/scope.sh
ANIM_PROBE_BYTES = 40
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


@lru_cache(maxsize=65536)
def _is_animated_webp(path: str, mtime_ns: int) -> bool:
    """imv can't load animated webp and silently drops it from its list.

    WHY: cache key has mtime so a rewritten file is re-probed; only 40 bytes read.
    DEBUG: unreadable file => False (treated as showable; imv count check will flag it).
    """
    try:
        with open(path, "rb") as f:
            return b"ANIM" in f.read(ANIM_PROBE_BYTES)
    except OSError:
        return False


def _imv_can_show(entry) -> bool:
    """Playlist membership == what imv will really keep in its own list.

    INVARIANT: ranger index N in playlist <=> imv index N; any file imv skips
      MUST be excluded here, else goto/back-sync shift by one and self-oscillate.
    EXTEND: add other imv-unloadable formats here (single place).
    """
    if entry.is_directory or not _looks_like_image(entry.path):
        return False
    if IMV_SKIP_ANIM and entry.path.lower().endswith(".webp"):
        stat_ = entry.stat
        # WHY: size gate first -- stat is already loaded by ranger, the probe opens a file
        if stat_ and stat_.st_size > IMV_ANIM_MIN_SIZE:
            return not _is_animated_webp(entry.path, stat_.st_mtime_ns)
    return True


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
        self.imv_index = {}  # realpath -> imv index as last observed ("name" mode hint)
        self.saved_preview = None  # preview_files value to restore; None = not hidden by us
        self._positions_src = None
        self._positions_map = {}
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
        self.imv_index = {}
        self.directory = getattr(self.fm.thisdir, "path", "")
        self.playlist_tab = self.fm.thistab
        self.observed_selection = None
        # self.pending = False
        self.pending = selected is not None  # new viewer: push ranger's playlist once
        self.last_poll = 0.0
        self.apply_preview_mode(selected is not None)
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

    def apply_preview_mode(self, tracking):
        """Hide ranger's preview while imv is tracked; restore afterwards.

        WHY preview_files: ranger then never spawns scope.sh and collapses the column;
          fm.previews cache is untouched so previews reappear instantly on restore.
        INVARIANT: only the first activation saves the value, so socket A -> B switches
          don't override a manual `zp` done during tracking.
        PROBABLY: redraw_window drops an already-drawn image overlay.
        """
        if not IMV_HIDE_PREVIEW:
            return
        settings = self.fm.settings
        if tracking:
            if self.saved_preview is not None:
                return
            self.saved_preview = bool(settings.preview_files)
            settings.preview_files = False
        elif self.saved_preview is not None:
            settings.preview_files = self.saved_preview
            self.saved_preview = None
        self.fm.ui.redraw_window()

    ## ALT: env-var variant (see IMV_COLLAPSE_IMAGE_PREVIEW above); scope.sh counterpart disabled too
    # def apply_preview_mode(self, tracking):
    #     """Tracking on => scope.sh refuses image previews => ranger collapses preview column.

    #     WHY env: ranger spawns scope.sh from its own process, so os.environ is inherited.
    #     DEBUG: ranger caches per-path preview verdicts (fm.previews); clear on every
    #       transition or stale "has preview"/"no preview" stays until file mtime changes.
    #     PROBABLY: redraw_window is needed to drop an already-drawn image overlay.
    #     """
    #     if not IMV_COLLAPSE_IMAGE_PREVIEW:
    #         return
    #     if tracking:
    #         os.environ[IMV_PREVIEW_ENV] = "1"
    #     else:
    #         os.environ.pop(IMV_PREVIEW_ENV, None)
    #     self.fm.previews.clear()
    #     self.fm.ui.redraw_window()

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
            self.imv_index = {}
            self.last_forward_index = None
            self.last_forward_time = None
            self.held_steps = 0
            directory_files = getattr(directory, "files", None)
            if entering and directory_files is None:
                return
            paths = tuple(
                entry.path
                for entry in (directory_files or ())
                # if not entry.is_directory and _looks_like_image(entry.path)
                # ## ALT: plain extension filter -- simpler/faster, but includes
                # ##   animated webp which imv skips => index shift + sync loop
                if _imv_can_show(entry)
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
                # DEBUG: "index" mode needs imv list == playlist; "name" tolerates dropped files
                if snapshot is None or (
                    IMV_SYNC_MODE == "index" and snapshot.count != len(paths)
                ):
                    self.pending = False
                    return
            observed = os.path.realpath(selected)
            if IMV_SYNC_MODE == "name":
                landed = self._goto_by_name(selected, index, paths)
                if landed is None:
                    self.playlist = ()
                    return
                observed = landed  # may be a neighbour; keeps back-sync from fighting ranger
            elif not _send_command(self.socket.path, f"goto {index}"):
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
        self.observed_selection = observed
        self.pending = False

    def _positions(self, paths):
        """realpath -> 1-based ranger playlist position; rebuilt only when the playlist changes."""
        if self._positions_src is not paths:
            self._positions_src = paths
            self._positions_map = {os.path.realpath(p): i for i, p in enumerate(paths, 1)}
        return self._positions_map

    def _goto_by_name(self, selected, index, paths):
        """Land imv on `selected` by verified path; return realpath where imv ended, None on IPC failure.

        ALGO: goto guess -> snapshot -> if landed elsewhere: guess = imv_index + (wanted_pos - landed_pos); repeat.
        WHY: imv list = playlist minus unloadable files, so imv index <= ranger index and every
          pass crosses >=1 dropped file => converges; `seen` stops oscillation when `selected`
          itself is dropped by imv (we then end on a neighbour).
        DEBUG: steps exhausted => imv stays on the last landed file; caller records it as
          observed_selection so back-sync sees no change (no scroll-by-itself loop).
        EXTEND: `imv_index` hint (path -> last seen imv index) makes repeated visits 1 pass.
        ALT: query imv for its path list up front -- probably impossible (no list command,
          and imv prunes failed files lazily after load attempts), so not implemented.
        """
        wanted = os.path.realpath(selected)
        positions = self._positions(paths)
        guess = self.imv_index.get(wanted, index)
        seen = set()
        landed = wanted
        for _ in range(IMV_NAME_SYNC_STEPS):
            guess = max(1, guess)
            if guess in seen:
                break
            seen.add(guess)
            if not _send_command(self.socket.path, f"goto {guess}"):
                return None
            snapshot = _snapshot(self.socket.path)
            if snapshot is None:
                return None
            landed = os.path.realpath(snapshot.path)
            self.imv_index[landed] = snapshot.index
            if landed == wanted:
                break
            at = positions.get(landed)
            if at is None:
                break  # imv shows a foreign file; nothing to correct against
            guess = min(snapshot.index + (index - at), snapshot.count or guess)
        return landed

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
        self.imv_index[path] = snapshot.index
        # INVARIANT: only "index" mode guarantees imv index == playlist index
        if (
            IMV_SYNC_MODE == "index"
            and self.playlist
            and 0 < snapshot.index <= len(self.playlist)
        ):
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
