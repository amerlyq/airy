"""Run from a ranger checkout: python3 -m unittest discover -s /d/airy/ranger/tests."""

import importlib.util
import os
import shlex
import socket
import subprocess
import unittest
from concurrent.futures import Future, ThreadPoolExecutor
from pathlib import Path
from tempfile import TemporaryDirectory
from threading import Event, Thread, get_ident
from types import SimpleNamespace
from unittest.mock import Mock, call, patch

import ranger.api
from ranger.api.commands import CommandContainer
from ranger.core.actions import Actions
from ranger.ext.keybinding_parser import KeyMaps
from ranger.ext.signals import SignalDispatcher


def load_plugin():
    spec = importlib.util.spec_from_file_location(
        "image_preview_imv2",
        Path(__file__).resolve().parents[1] / "plugins/image_preview_imv2.py",
    )
    plugin = importlib.util.module_from_spec(spec)
    with patch.object(ranger.api, "hook_ready"):
        spec.loader.exec_module(plugin)
    return plugin


class ImmediateExecutor:
    """Deterministic completed polls; race tests explicitly hold a Future open."""

    def submit(self, function, *args):
        future = Future()
        try:
            future.set_result(function(*args))
        except Exception as error:
            future.set_exception(error)
        return future


class FileManager(SignalDispatcher):
    """Real ranger signals/keymaps/commands; directory movement without curses."""

    select_file = Actions.select_file

    def __init__(self, paths):
        super().__init__()
        self.thisdir = SimpleNamespace(
            path=str(paths[0].parent),
            files=[
                SimpleNamespace(path=str(path), is_directory=False) for path in paths
            ],
            move_to_obj=self.move_to_obj,
        )
        self.thisfile = self.thisdir.files[0]
        self.thistab = object()
        maps = KeyMaps()
        for key, command in {"i": "display_file", "m": {ord("a"): "mark a"}}.items():
            maps.bind("browser", key, command)
        self.ui = SimpleNamespace(
            keymaps=maps,
            handle_input=lambda: None,
            load_mode=False,
            handle_key=Mock(),
            handle_mouse=Mock(),
        )
        self.settings = SimpleNamespace(idle_delay=2000)
        self.commands = CommandContainer()
        self.rifle = SimpleNamespace(hook_after_executing=Mock())
        self.notify = Mock()

    def enter_dir(self, path):
        return path == self.thisdir.path

    def move_to_obj(self, path):
        previous = self.thisfile
        self.thisfile = next(
            entry for entry in self.thisdir.files if entry.path == path
        )
        self.signal_emit("move", previous=previous, new=self.thisfile, tab=self.thistab)


class ImvSyncTests(unittest.TestCase):
    def setUp(self):
        self.plugin = load_plugin()
        directory = TemporaryDirectory()
        self.addCleanup(directory.cleanup)
        self.paths = [
            Path(directory.name) / name for name in ("a.png", "b.png", "c.png")
        ]
        for path in self.paths:
            path.touch()
        self.fm = FileManager(self.paths)
        self.original_rifle_after = self.fm.rifle.hook_after_executing
        self.sockets = {}
        for name, replacement in {
            "ThreadPoolExecutor": Mock(return_value=ImmediateExecutor()),
            "_sockets": Mock(
                side_effect=lambda: {
                    self.plugin.SocketInfo(path, *identity)
                    for path, identity in self.sockets.items()
                }
            ),
            "_snapshot": Mock(
                return_value=self.plugin.Snapshot(str(self.paths[1]), 2, 3)
            ),
            "_send_command": Mock(return_value=True),
        }.items():
            patcher = patch.object(self.plugin, name, replacement)
            patcher.start()
            self.addCleanup(patcher.stop)
        patcher = patch.object(self.plugin.curses, "halfdelay")
        self.halfdelay = patcher.start()
        self.addCleanup(patcher.stop)
        self.sync = self.plugin.ImvSync(self.fm)
        self.sync.install()
        self.sockets["imv.sock"] = (1, 10, 100)
        self.sync.discover()
        self.observer = Mock()
        self.fm.signal_bind("move", lambda signal: self.observer(signal), weak=False)

    def sent(self):
        return [item.args[1] for item in self.plugin._send_command.call_args_list]

    def move(self, index):
        self.fm.select_file(str(self.paths[index]))

    def test_passive_sync_preserves_other_move_handlers(self):
        self.sync.sync_from_imv()
        self.sync.sync_to_imv()
        self.assertEqual(self.fm.thisfile.path, str(self.paths[1]))
        self.assertEqual(self.sent(), [])
        self.observer.assert_called_once()

    def test_rapid_imv_changes_never_echo(self):
        for index in (1, 2, 0, 2, 1, 0):
            self.plugin._snapshot.return_value = self.plugin.Snapshot(
                str(self.paths[index]), index + 1, 3
            )
            self.sync.sync_from_imv()
            self.sync.sync_to_imv()
            self.assertEqual(self.fm.thisfile.path, str(self.paths[index]))
        self.assertEqual(self.sent(), [])

    def test_input_takes_priority_over_poll_and_coalesces_intermediate_moves(self):
        self.sync.original_input = lambda: (self.move(0), self.move(2))
        self.fm.ui.handle_input()
        self.assertEqual(self.fm.thisfile.path, str(self.paths[2]))
        self.assertEqual(
            [cmd for cmd in self.sent() if cmd.startswith("goto")], ["goto 3"]
        )
        self.assertEqual(self.halfdelay.call_args_list, [call(3), call(20)])
        self.plugin._snapshot.assert_not_called()

    def test_fast_ranger_moves_do_not_drop_final_selection(self):
        self.move(1)
        self.sync.sync_to_imv()
        self.move(2)
        self.sync.sync_to_imv()
        self.assertEqual(self.sent()[-1], "goto 3")
        self.assertEqual(self.sent().count("close all"), 1)

    def start_delayed_poll(self):
        future = Future()
        self.sync.executor.submit = Mock(return_value=future)
        self.sync.sync_from_imv()
        return future

    def test_completed_old_poll_cannot_undo_immediate_down(self):
        future = self.start_delayed_poll()
        future.set_result(self.plugin.Snapshot(str(self.paths[0]), 1, 3))
        self.sync.original_input = lambda: self.move(1)
        self.fm.ui.handle_input()
        self.sync.original_input = lambda: None
        self.fm.ui.handle_input()  # Drain stale result on the next idle iteration.
        self.assertEqual(self.fm.thisfile.path, str(self.paths[1]))
        self.assertEqual(
            [cmd for cmd in self.sent() if cmd.startswith("goto")], ["goto 2"]
        )
        self.assertIsNone(self.sync.snapshot_job)

    def test_poll_finishing_after_down_is_discarded(self):
        future = self.start_delayed_poll()
        self.sync.original_input = lambda: self.move(1)
        self.fm.ui.handle_input()
        future.set_result(self.plugin.Snapshot(str(self.paths[0]), 1, 3))
        self.sync.original_input = lambda: None
        self.fm.ui.handle_input()
        self.assertEqual(self.fm.thisfile.path, str(self.paths[1]))
        self.assertIsNone(self.sync.snapshot_job)

    def test_parent_navigation_rejects_old_and_fresh_imv_results(self):
        future = self.start_delayed_poll()
        parent = str(self.paths[0].parent.parent)
        pics = SimpleNamespace(path=str(self.paths[0].parent), is_directory=True)

        def go_parent():
            self.fm.thisdir = SimpleNamespace(
                path=parent,
                files=[pics],
                move_to_obj=self.fm.move_to_obj,
            )
            self.fm.thisfile = pics
            self.fm.signal_emit("move", new=pics, tab=self.fm.thistab)

        self.sync.original_input = go_parent
        self.fm.ui.handle_input()
        future.set_result(self.plugin.Snapshot(str(self.paths[2]), 3, 3))
        self.sync.original_input = lambda: None
        self.fm.ui.handle_input()
        self.sync.executor = ImmediateExecutor()
        self.sync.sync_from_imv()  # Even a fresh poll cannot re-enter pics.
        self.assertEqual(self.fm.thisdir.path, parent)
        self.assertIs(self.fm.thisfile, pics)
        self.assertEqual(self.sent(), [])

    def test_key_without_cursor_movement_invalidates_poll(self):
        future = self.start_delayed_poll()
        self.sync.original_input = lambda: self.fm.ui.handle_key(258)
        self.fm.ui.handle_input()
        future.set_result(self.plugin.Snapshot(str(self.paths[2]), 3, 3))
        self.sync.original_input = lambda: None
        self.fm.ui.handle_input()
        self.assertEqual(self.fm.thisfile.path, str(self.paths[0]))

    def test_mouse_input_invalidates_poll_without_focus_notifications(self):
        future = self.start_delayed_poll()
        self.sync.original_input = self.fm.ui.handle_mouse
        self.fm.ui.handle_input()
        future.set_result(self.plugin.Snapshot(str(self.paths[2]), 3, 3))
        self.sync.original_input = lambda: None
        self.fm.ui.handle_input()
        self.assertEqual(self.fm.thisfile.path, str(self.paths[0]))

    def test_actual_worker_does_not_block_input_or_apply_stale_result(self):
        started, release = Event(), Event()
        worker_ids = []

        def delayed_snapshot(sock):
            worker_ids.append(get_ident())
            started.set()
            release.wait(2)
            return self.plugin.Snapshot(str(self.paths[0]), 1, 3)

        self.plugin._snapshot.side_effect = delayed_snapshot
        with ThreadPoolExecutor(max_workers=1) as executor:
            self.sync.executor = executor
            try:
                self.sync.sync_from_imv()
                self.assertTrue(started.wait(1))
                future = self.sync.snapshot_job[1]
                self.assertFalse(future.done())
                self.sync.original_input = lambda: self.move(1)
                self.fm.ui.handle_input()
                self.assertEqual(self.fm.thisfile.path, str(self.paths[1]))
                self.assertFalse(future.done())
            finally:
                release.set()
            future.result(timeout=2)
            self.sync.original_input = lambda: None
            self.fm.ui.handle_input()
            self.assertEqual(self.fm.thisfile.path, str(self.paths[1]))
            self.assertNotEqual(worker_ids, [get_ident()])

    def test_selection_error_does_not_leave_back_sync_guard_set(self):
        with patch.object(
            self.fm.thisdir, "move_to_obj", side_effect=RuntimeError("failed")
        ):
            with self.assertRaisesRegex(RuntimeError, "failed"):
                self.sync.sync_from_imv()
        self.move(2)
        self.sync.sync_to_imv()
        self.assertEqual(self.sent()[-1], "goto 3")

    def test_pending_ranger_selection_blocks_poll_until_sent(self):
        self.move(2)
        self.sync.sync_from_imv()
        self.plugin._snapshot.assert_not_called()
        self.plugin._send_command.return_value = False
        self.sync.sync_to_imv()
        self.assertTrue(self.sync.pending)
        self.sync.sync_from_imv()
        self.plugin._snapshot.assert_not_called()
        self.plugin._send_command.return_value = True
        self.sync.sync_to_imv()
        self.assertFalse(self.sync.pending)

    def test_partial_playlist_failure_rebuilds_before_retry(self):
        self.move(1)
        self.plugin._send_command.side_effect = [True, False]
        self.sync.sync_to_imv()
        self.assertEqual(self.sync.playlist, ())
        self.plugin._send_command.side_effect = None
        self.sync.sync_to_imv()
        self.assertEqual(self.sent().count("close all"), 2)
        self.assertEqual(self.sent()[-1], "goto 2")

    def test_sort_and_filter_changes_rebuild_exact_visible_playlist(self):
        self.move(1)
        self.sync.sync_to_imv()
        self.fm.thisdir.files.reverse()
        self.fm.thisdir.files.pop(1)
        self.move(0)
        self.sync.sync_to_imv()
        self.assertEqual(self.sync.playlist, (str(self.paths[2]), str(self.paths[0])))
        self.assertEqual(shlex.split(self.sent()[-2])[1:], list(self.sync.playlist))
        self.assertEqual(self.sent()[-1], "goto 2")

    def test_nonimages_and_directories_are_not_added(self):
        self.fm.thisdir.files.append(
            SimpleNamespace(path="/tmp/text.txt", is_directory=False)
        )
        self.fm.thisdir.files.append(
            SimpleNamespace(path="/tmp/folder.png", is_directory=True)
        )
        self.move(1)
        self.sync.sync_to_imv()
        self.assertEqual(self.sync.playlist, tuple(map(str, self.paths)))
        self.fm.move_to_obj("/tmp/text.txt")
        self.sync.sync_to_imv()
        self.sync.sync_from_imv()
        self.assertEqual(self.fm.thisfile.path, "/tmp/text.txt")

    def test_changed_imv_playlist_invalidates_cached_indices(self):
        self.move(1)
        self.sync.sync_to_imv()
        self.plugin._snapshot.return_value = self.plugin.Snapshot(
            str(self.paths[1]), 1, 2
        )
        self.sync.sync_from_imv()
        self.assertEqual(self.sync.playlist, ())
        self.move(2)
        self.sync.sync_to_imv()
        self.assertEqual(self.sent().count("close all"), 2)

    def test_same_length_imv_playlist_edit_invalidates_cached_indices(self):
        self.move(1)
        self.sync.sync_to_imv()
        self.plugin._snapshot.return_value = self.plugin.Snapshot(
            str(self.paths[1]), 1, 3
        )
        self.sync.sync_from_imv()
        self.assertEqual(self.sync.playlist, ())

    def test_symlink_back_sync_keeps_ranger_alias(self):
        link = self.paths[1].parent / "alias.png"
        link.symlink_to(self.paths[1])
        self.fm.thisdir.files[1].path = str(link)
        self.sync.sync_from_imv()
        self.assertEqual(self.fm.thisfile.path, str(link))
        self.assertEqual(self.sent(), [])

    def test_back_sync_does_not_enter_directories(self):
        self.fm.thisdir.path = "/another-directory"
        self.sync.sync_from_imv()
        self.observer.assert_not_called()

    def test_other_tab_moves_do_not_drive_imv(self):
        self.fm.signal_emit("move", new=self.fm.thisfile, tab=object())
        self.sync.sync_to_imv()
        self.assertEqual(self.sent(), [])

    def test_stop_restores_prefix_and_absent_maps_then_accepts_new_socket(self):
        self.fm.commands.get_command("stop_imv_tracking")("stop_imv_tracking").execute()
        maps = self.fm.ui.keymaps["browser"]
        self.assertEqual(maps[ord("i")], "display_file")
        self.assertEqual(maps[ord("m")], {ord("a"): "mark a"})
        self.assertNotIn(ord("M"), maps)
        self.sync.discover()
        self.assertIsNone(self.sync.socket)
        self.sockets["new.sock"] = (1, 11, 101)
        self.sync.discover()
        self.assertEqual(self.sync.socket.path, "new.sock")

    def test_socket_replacement_resets_state_even_at_same_path(self):
        self.move(1)
        self.sync.sync_to_imv()
        self.sync.stop()
        self.sockets["imv.sock"] = (1, 12, 102)
        self.sync.discover()
        self.assertIsNotNone(self.sync.socket)
        self.assertEqual(self.sync.playlist, ())
        self.assertIsNone(self.sync.observed_selection)

    def test_preexisting_sockets_stay_ignored(self):
        other = self.plugin.ImvSync(self.fm)
        other.discover()
        self.assertIsNone(other.socket)

    def test_disappearing_socket_restores_maps_without_overwriting_user_edit(self):
        self.fm.ui.keymaps.bind("browser", "i", "custom_action")
        self.sockets.clear()
        self.sync.discover()
        maps = self.fm.ui.keymaps["browser"]
        self.assertEqual(maps[ord("i")], "custom_action")
        self.assertEqual(maps[ord("m")], {ord("a"): "mark a"})

    def test_input_failure_restores_curses_wait(self):
        self.sync.original_input = Mock(side_effect=RuntimeError("input failed"))
        with self.assertRaisesRegex(RuntimeError, "input failed"):
            self.fm.ui.handle_input()
        self.assertEqual(self.halfdelay.call_args_list, [call(3), call(20)])

    def test_background_loader_retains_nonblocking_input(self):
        self.fm.ui.load_mode = True
        self.fm.ui.handle_input()
        self.halfdelay.assert_not_called()

    def test_rifle_hook_preserves_previous_result(self):
        self.original_rifle_after.return_value = "previous result"
        self.assertEqual(
            self.fm.rifle.hook_after_executing("argument"), "previous result"
        )
        self.original_rifle_after.assert_called_once_with("argument")

    def test_oversized_path_does_not_clear_viewer(self):
        self.fm.thisfile.path = "/" + "x" * 1100 + ".png"
        self.sync.pending = True
        self.sync.sync_to_imv()
        self.assertEqual(self.sent(), [])
        self.fm.notify.assert_called_once()

    def test_duplicate_symlink_targets_follow_imv_index(self):
        link = self.paths[1].parent / "alias.png"
        link.symlink_to(self.paths[1])
        self.fm.thisdir.files.append(
            SimpleNamespace(path=str(link), is_directory=False)
        )
        self.move(1)
        self.sync.sync_to_imv()
        self.plugin._snapshot.return_value = self.plugin.Snapshot(
            str(self.paths[1]), 4, 4
        )
        self.sync.sync_from_imv()
        self.assertEqual(self.fm.thisfile.path, str(link))

    def test_snapshot_filesystem_error_is_recoverable(self):
        self.plugin._snapshot.side_effect = OSError("temporary storage unavailable")
        self.sync.sync_from_imv()
        self.assertEqual(self.fm.thisfile.path, str(self.paths[0]))
        self.assertEqual(self.sent(), [])


class TransportTests(unittest.TestCase):
    def setUp(self):
        self.plugin = load_plugin()

    def test_quoted_paths_roundtrip_through_shell_expansion(self):
        paths = tuple(
            "/tmp/" + name
            for name in (
                "with space.png",
                "quote'\".png",
                "$(printf injected).png",
                "`printf injected`.png",
                "back\\slash.png",
                "line\nbreak.png",
                "*.png",
                "semi;colon.png",
                "trailing.png ",
                "nonutf-\udcff.png",
            )
        )
        result = b"".join(
            subprocess.check_output(["sh", "-c", "printf '%s\\0' " + command[5:]])
            for command in self.plugin._open_commands(paths)
        )
        self.assertEqual(result.split(b"\0")[:-1], list(map(os.fsencode, paths)))

    def test_chunk_limits_use_encoded_bytes_and_preserve_order(self):
        paths = tuple(f"/tmp/{index}-{'é' * 60}.png" for index in range(50))
        commands = self.plugin._open_commands(paths)
        self.assertGreater(len(commands), 1)
        self.assertTrue(
            all(
                len(os.fsencode(cmd + "\n")) <= self.plugin.IPC_MAX_BYTES
                for cmd in commands
            )
        )
        self.assertEqual(
            [path for cmd in commands for path in shlex.split(cmd)[1:]], list(paths)
        )

    def test_real_unix_socket_eof_and_snapshot_without_ipc_reply(self):
        with TemporaryDirectory(prefix="imv-test-") as directory:
            address = str(Path(directory) / "imv.sock")
            received = []
            errors = []
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as server:
                server.bind(address)
                server.listen()
                server.settimeout(2)

                def serve():
                    try:
                        for _ in range(2):
                            connection, _ = server.accept()
                            with connection:
                                command = connection.recv(1023).decode().rstrip("\n")
                                received.append(command)
                                if command.startswith("exec "):
                                    subprocess.run(
                                        ["sh", "-c", command[5:]],
                                        check=True,
                                        env={
                                            **os.environ,
                                            "imv_current_file": " /tmp/line\nbreak.png ",
                                            "imv_current_index": "2",
                                            "imv_file_count": "3",
                                        },
                                    )
                                # imv sends no reply; reads EOF then closes.
                                self.assertEqual(connection.recv(1), b"")
                    except Exception as error:
                        errors.append(error)

                worker = Thread(target=serve, daemon=True)
                worker.start()
                self.assertTrue(self.plugin._send_command(address, "goto 2"))
                snapshot = self.plugin._snapshot(address)
                worker.join(3)
                self.assertFalse(worker.is_alive())
                self.assertEqual(errors, [])
                self.assertEqual(received[0], "goto 2")
                self.assertEqual(
                    snapshot, self.plugin.Snapshot(" /tmp/line\nbreak.png ", 2, 3)
                )

    def test_missing_socket_is_recoverable(self):
        self.assertFalse(self.plugin._send_command("/nonexistent/imv.sock", "goto 1"))

    def test_snapshot_timeout_removes_private_directory(self):
        with TemporaryDirectory() as directory:
            with (
                patch.object(self.plugin.tempfile, "tempdir", directory),
                patch.object(self.plugin, "_send_command", return_value=True),
                patch.object(self.plugin.time, "monotonic", side_effect=[0, 1]),
            ):
                self.assertIsNone(self.plugin._snapshot("imv.sock"))
            self.assertEqual(list(Path(directory).iterdir()), [])

    def test_discovery_ignores_regular_files(self):
        with TemporaryDirectory() as directory:
            Path(directory, "imv-regular.sock").touch()
            path = str(Path(directory) / "imv-real.sock")
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as server:
                server.bind(path)
                with patch.dict(os.environ, XDG_RUNTIME_DIR=directory):
                    found = self.plugin._sockets()
                self.assertEqual({item.path for item in found}, {path})


if __name__ == "__main__":
    unittest.main()
