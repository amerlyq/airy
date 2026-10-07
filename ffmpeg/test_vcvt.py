"""Run: python3.14 -m unittest discover -s ffmpeg -p 'test_*.py'."""

import importlib.util
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "vcvt", Path(__file__).with_name("vcvt.py")
)
vcvt = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(vcvt)


class ConversionTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / "input.mp4"
        self.source.write_bytes(b"original source")
        self.args = vcvt.parser().parse_args(["--encoder", "cpu", "-c32"])
        with patch.dict(os.environ, {}, clear=True):
            vcvt.encoder(self.args)
        self.output = self.root / "input_v32.mp4"

    def encode(self, argv, **kwargs):
        Path(argv[-1]).write_bytes(b"new encoded output")

    def test_recursive_expansion_deduplicates_and_excludes_generated(self):
        sub = self.root / "sub"
        sub.mkdir()
        (sub / "other.MP4").touch()
        self.output.touch()
        (sub / "other_q28.mp4").touch()
        files = vcvt.collect([self.root, self.source])
        self.assertEqual(files, [self.source, sub / "other.MP4"])

    def test_symlink_path_stays_unresolved(self):
        alias = self.root / "alias.mp4"
        alias.symlink_to(self.source)
        self.assertEqual(vcvt.collect([alias]), [alias])

    def test_failure_preserves_previous_output(self):
        self.output.write_bytes(b"previous output")
        with patch.object(
            vcvt, "run", side_effect=subprocess.CalledProcessError(1, "ffmpeg")
        ):
            with self.assertRaises(subprocess.CalledProcessError):
                vcvt.convert(self.args, self.source)
        self.assertEqual(self.output.read_bytes(), b"previous output")
        self.assertFalse(list(self.root.glob(".vcvt-*")))
        self.assertFalse(list(self.root.glob("*_prev*")))

    def test_invalid_output_is_not_published(self):
        with (
            patch.object(vcvt, "run", side_effect=self.encode),
            patch.object(vcvt, "probe", return_value={"codec_name": "h264"}),
        ):
            with self.assertRaises(ValueError):
                vcvt.convert(self.args, self.source)
        self.assertFalse(self.output.exists())

    def test_success_creates_numbered_backup(self):
        self.output.write_bytes(b"previous output")
        with (
            patch.object(vcvt, "run", side_effect=self.encode) as run,
            patch.object(vcvt, "probe", return_value={"codec_name": "av1"}),
        ):
            vcvt.convert(self.args, self.source)
        self.assertEqual(run.call_args.args[0][-1], str(self.output) + ".cvt")
        self.assertEqual(self.output.read_bytes(), b"new encoded output")
        self.assertFalse((self.root / "input_v32.mp4.cvt").exists())
        self.assertEqual(
            (self.root / "input_v32_prev1.mp4").read_bytes(), b"previous output"
        )
        self.assertEqual(self.source.read_bytes(), b"original source")

    def test_job_number_is_added_to_conversion_marker(self):
        with (
            patch.dict(os.environ, {"VCVT_JOB_ID": "8"}),
            patch.object(vcvt, "run", side_effect=self.encode) as run,
            patch.object(vcvt, "probe", return_value={"codec_name": "av1"}),
        ):
            vcvt.convert(self.args, self.source)
        self.assertEqual(run.call_args.args[0][-1], str(self.output) + ".cvt-job8")

    def test_skip_existing_only_applies_to_directory_discovery(self):
        self.output.touch()
        with (
            patch.dict(os.environ, {"VCVT_SKIP_EXISTING": "1"}),
            patch.object(vcvt, "eligible", return_value=[self.source]),
            patch.object(vcvt, "convert") as convert,
        ):
            vcvt.main(["--encoder", "cpu", "-i", str(self.root)])
            convert.assert_not_called()
            vcvt.main(["--encoder", "cpu", "-i", str(self.source)])
        convert.assert_called_once()
        self.assertEqual(convert.call_args.args[1], self.source)

    def test_changed_input_prevents_publication(self):
        def changed(argv, **kwargs):
            self.encode(argv)
            self.source.write_bytes(b"modified during conversion")

        with (
            patch.object(vcvt, "run", side_effect=changed),
            patch.object(vcvt, "probe", return_value={"codec_name": "av1"}),
        ):
            with self.assertRaises(ValueError):
                vcvt.convert(self.args, self.source)
        self.assertFalse(self.output.exists())

    def test_dry_run_creates_no_files(self):
        self.args.d = True
        before = sorted(self.root.iterdir())
        with patch.object(vcvt, "run", side_effect=AssertionError("must not execute")):
            vcvt.convert(self.args, self.source)
        self.assertEqual(sorted(self.root.iterdir()), before)

    def test_move_does_not_overwrite_collision(self):
        self.output.write_bytes(b"keep")
        with self.assertRaises(FileExistsError):
            vcvt.move_no_replace(self.source, self.output)
        self.assertEqual(self.output.read_bytes(), b"keep")
        self.assertTrue(self.source.exists())

    def test_archive_rolls_back_first_move_if_second_fails(self):
        queue = self.root / "queue"
        queue.mkdir()
        source = queue / "x.mp4"
        output = queue / "x_v32.mp4"
        source.write_bytes(b"input")
        output.write_bytes(b"output")
        move = vcvt.move_no_replace

        def fail_second(src, dst):
            if src == output:
                raise OSError("simulated failure")
            move(src, dst)

        with patch.object(vcvt, "move_no_replace", side_effect=fail_second):
            with self.assertRaises(OSError):
                vcvt.archive(source, output)
        self.assertTrue(source.exists())
        self.assertTrue(output.exists())
        self.assertFalse((self.root / "done" / source.name).exists())

    def test_intel_selects_qsv(self):
        args = vcvt.parser().parse_args(["-g"])
        with (
            patch.dict(os.environ, {}, clear=True),
            patch.object(Path, "exists", lambda path: str(path) == "/sys/module/i915"),
        ):
            vcvt.encoder(args)
        self.assertEqual((args.encoder, args.tag, args.c), ("qsv", "q", 28))

    def test_enqueue_uses_python_executor_and_single_process_worker(self):
        with patch.object(vcvt, "run") as run:
            vcvt.enqueue(self.args, [self.source])
        command = run.call_args.args[0]
        self.assertIn(str(vcvt.SELF), command)
        self.assertIn("-i", command)
        self.assertTrue(any(item.endswith("tmux-jobs.py") for item in command))
        self.assertEqual(
            run.call_args.kwargs["input"], os.fsencode(self.source) + b"\0"
        )

    def test_gpu_commands_keep_audio_and_do_not_prompt(self):
        for backend in ("cpu", "nv", "qsv"):
            self.args.encoder = backend
            command = vcvt.command(self.args, self.source, self.output)
            self.assertIn("-nostdin", command)
            self.assertIn("-n", command)
            self.assertEqual(command[command.index("-c:a") + 1], "copy")

    @unittest.skipUnless(os.sys.platform.startswith("linux"), "inotify requires Linux")
    def test_watch_moves_closed_file_with_newline_name_before_submission(self):
        todo = self.root / "todo"
        todo.mkdir()
        self.args.paths = [str(todo)]
        self.args.w = True
        name = "quotes' and\nnewline.mp4"
        original_select = vcvt.select.select
        created = False
        submissions = []

        def arrival(*args):
            nonlocal created
            if not created:
                created = True
                (todo / name).write_bytes(b"completed video")
            return original_select(*args)

        def submitted(args, files):
            submissions.extend(files)
            raise RuntimeError("stop test watcher")

        with (
            patch.object(vcvt.select, "select", side_effect=arrival),
            patch.object(vcvt, "eligible", side_effect=lambda files: files),
            patch.object(vcvt, "enqueue", side_effect=submitted),
        ):
            with self.assertRaisesRegex(RuntimeError, "stop test watcher"):
                vcvt.watch(self.args)
        self.assertEqual(submissions, [self.root / "queue" / name])
        self.assertEqual(submissions[0].read_bytes(), b"completed video")
        self.assertFalse((todo / name).exists())

    def test_cross_filesystem_move_stages_copy(self):
        original_link = os.link

        def link(source, target, **kwargs):
            if source == self.source:
                raise OSError(vcvt.errno.EXDEV, "cross-device link")
            return original_link(source, target, **kwargs)

        with patch.object(vcvt.os, "link", side_effect=link):
            vcvt.move_no_replace(self.source, self.output)
        self.assertFalse(self.source.exists())
        self.assertEqual(self.output.read_bytes(), b"original source")


if __name__ == "__main__":
    unittest.main()
