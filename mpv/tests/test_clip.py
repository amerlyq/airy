"""Run with FFmpeg/ffprobe and Lua on PATH: python3 -m unittest discover -s mpv/tests -v."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
RUN = ROOT / "ffmpeg/run"
DRIVER = ROOT / "mpv/tests/clip_driver.lua"
FFMPEG = shutil.which("ffmpeg")
LUA = shutil.which("lua") or shutil.which("luajit")


def run(args):
    return subprocess.run(list(map(str, args)), check=True, capture_output=True).stdout


def ff(*args):
    return run([FFMPEG, "-v", "error", "-nostdin", *args])


def preview_plan(source, a, b, mode, which, output, window=2):
    encoded = run([RUN, "--preview-plan", which, source, a, b, mode, output, window])
    return [[s.decode() for s in c.split(b"\0")] for c in encoded.split(b"\0\0") if c]


def frames(path, vf="scale=160:90"):
    data = ff("-i", path, "-an", "-sn", "-dn", "-vf", vf,
              "-pix_fmt", "bgra", "-fps_mode", "passthrough", "-f", "rawvideo", "-")
    size = 160 * 90 * 4
    assert len(data) % size == 0
    return [data[i:i + size] for i in range(0, len(data), size)]


@unittest.skipUnless(LUA, "Lua required")
class LifecycleTests(unittest.TestCase):
    def test_callback_lifecycle(self):
        run([LUA, DRIVER, "lifecycle", ROOT / "mpv/scripts/clip.lua"])


@unittest.skipUnless(FFMPEG and shutil.which("ffprobe"), "FFmpeg and ffprobe required")
class BoundaryTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="clip-tests-")
        cls.folder = Path(cls.temp.name)
        cls.source = cls.folder / "source with 'quote.mp4"
        ff("-f", "lavfi", "-i", "testsrc2=size=160x90:rate=30",
           "-f", "lavfi", "-i", "sine=frequency=1000:sample_rate=48000",
           "-t", "24", "-c:v", "mpeg4", "-q:v", "3", "-bf", "2",
           "-g", "120", "-c:a", "aac", cls.source)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def compare(self, source, a, b, mode):
        with tempfile.TemporaryDirectory(dir=self.folder) as td:
            folder = Path(td)
            exports = folder / "export"
            run([RUN, source, a, b, mode, exports])
            output, = exports.iterdir()
            actual = frames(output)
            for which in ("A", "B"):
                preview = folder / (which + source.suffix)
                plan = preview_plan(source, a, b, mode, which, preview)
                for cmd in plan:
                    run(cmd)
                sample = frames(preview)
                with self.subTest(mode=mode, source=source.name, a=a, b=b, which=which):
                    self.assertEqual(actual[:1] if which == "A" else actual[-1:],
                                     sample[:1] if which == "A" else sample[-1:])

    def compare_frame_identity(self, source, a, b, mode):
        references = frames(source)
        def closest(frame):
            return min(range(len(references)), key=lambda i:
                       sum((a-b)**2 for a, b in zip(frame[::16], references[i][::16])))
        with tempfile.TemporaryDirectory(dir=self.folder) as td:
            folder = Path(td)
            exports = folder / "export"
            run([RUN, source, a, b, mode, exports])
            output, = exports.iterdir()
            actual = frames(output)
            for which in ("A", "B"):
                preview = folder / (which + source.suffix)
                for cmd in preview_plan(source, a, b, mode, which, preview):
                    run(cmd)
                sample = frames(preview)
                index = 0 if which == "A" else -1
                self.assertEqual(closest(actual[index]), closest(sample[index]))

    def test_copy_matches_full_export(self):
        mkv = self.folder / "source.mkv"
        ff("-i", self.source, "-c", "copy", mkv)
        for source in (self.source, mkv):
            for a, b in ((0, 15), (5.123, 18.456), (5.123, 5.4),
                         (4, 8), (10, 24), (5.99, 6.01), (23.99, 24)):
                self.compare(source, a, b, "copy")

    def test_preview_plan_never_encodes_full_fast_span(self):
        for which in ("A", "B"):
            cmd, = preview_plan(self.source, 5, 23, "fast", which, self.folder / "fast.mp4")
            begin = float(cmd[cmd.index("-ss") + 1])
            end = float(cmd[cmd.index("-to") + 1])
            self.assertLessEqual(end - begin, 2)
            self.assertLess(cmd.index("-ss"), cmd.index("-i"))
            self.assertIn("hevc_qsv", cmd)
            self.assertIn("passthrough", cmd)

    @unittest.skipUnless(LUA, "Lua required")
    def test_sparse_frames_retry_window(self):
        source = self.folder / "sparse.mp4"
        ff("-f", "lavfi", "-i", "testsrc2=size=160x90:rate=1/5",
           "-t", "20", "-c:v", "mpeg4", "-g", "2", source)
        with tempfile.TemporaryDirectory(dir=self.folder) as td:
            # Neither initial two-second window contains a displayable frame.
            run([LUA, DRIVER, "frames", source, td, 1, 19])
            self.assertEqual(160 * 90 * 4, (Path(td) / "A.raw").stat().st_size)
            self.assertEqual(160 * 90 * 4, (Path(td) / "B.raw").stat().st_size)

    def test_copy_nonzero_start_time(self):
        source = self.folder / "offset.mp4"
        ff("-i", self.source, "-c", "copy", "-output_ts_offset", "3", source)
        self.compare(source, 5.123, 18.456, "copy")

    @unittest.skipUnless(LUA, "Lua required")
    def test_audio_outlasts_video(self):
        source = self.folder / "audio-tail.mp4"
        ff("-i", self.source, "-vf", "trim=end=6", "-c:v", "mpeg4",
           "-c:a", "copy", source)
        with tempfile.TemporaryDirectory(dir=self.folder) as td:
            run([LUA, DRIVER, "frames", source, td, 5.1, 23])
            self.assertEqual(160 * 90 * 4, (Path(td) / "B.raw").stat().st_size)

    def test_smart_boundary_segments_match_export(self):
        if b"libx264" not in ff("-encoders"):
            self.skipTest("libx264 required")
        source = self.folder / "h264.mp4"
        ff("-i", self.source, "-c:v", "libx264", "-crf", "18", "-g", "120",
           "-keyint_min", "120", "-sc_threshold", "0", "-c:a", "copy", source)
        # Both ends re-encoded; both on keyframes; first/last segment omitted.
        for a, b in ((5.123, 18.456), (4, 16), (4, 18.456), (5.123, 16)):
            self.compare_frame_identity(source, a, b, "smart")
            for which in ("A", "B"):
                cmd = preview_plan(source, a, b, "smart", which, self.folder / "smart.mp4")[0]
                self.assertLessEqual(float(cmd[cmd.index("-to") + 1]) -
                                     float(cmd[cmd.index("-ss") + 1]), 2.000001)
        # Entire range needs re-encoding; short previews may compress differently.
        self.compare_frame_identity(source, 4.1, 7.9, "smart")
        vfr = self.folder / "h264-vfr.mkv"
        ff("-i", source, "-vf", "select='if(lt(t,12),not(mod(n,2)),not(mod(n,3)))'",
           "-fps_mode", "vfr", "-c:v", "libx264", "-g", "60",
           "-keyint_min", "60", "-sc_threshold", "0", "-c:a", "copy", vfr)
        self.compare_frame_identity(vfr, 5.123, 18.456, "smart")

    @unittest.skipUnless(LUA, "Lua required")
    def test_copy_key_exports_after_previews(self):
        with tempfile.TemporaryDirectory(dir=self.folder) as td:
            folder = Path(td)
            source = folder / "copy-key.mp4"
            shutil.copyfile(self.source, source)
            run([LUA, DRIVER, "export", source, folder, 5.123, 18.456])
            outputs = [p for p in folder.glob("*.mp4") if p != source]
            self.assertEqual(len(outputs), 1)
            self.assertGreater(len(frames(outputs[0])), 0)

    @unittest.skipUnless(LUA, "Lua required")
    def test_lua_pixels_match_copy_export(self):
        with tempfile.TemporaryDirectory(dir=self.folder) as td:
            folder = Path(td)
            run([LUA, DRIVER, "frames", self.source, folder, 5.123, 18.456])
            exports = folder / "export"
            run([RUN, self.source, 5.123, 18.456, "copy", exports])
            output, = exports.iterdir()
            for which, label in (("A", "00\\:05.1"), ("B", "00\\:18.4")):
                vf = (f"scale=160:90,drawtext=text='copy {which} {label}':"
                      "x=10:y=h-th-10:fontsize=12:fontcolor=white:borderw=2:bordercolor=black")
                decoded = frames(output, vf)
                expected = decoded[0] if which == "A" else decoded[-1]
                self.assertEqual(expected, (folder / (which + ".raw")).read_bytes())

    @unittest.skipUnless(os.environ.get("CLIP_TEST_QSV") == "1", "Intel QSV hardware required")
    def test_fast_frame_selection(self):
        # Lossy samples need not be bit-identical. Check source-frame identity
        # by nearest reference after downscaling rather than hashing pixels.
        self.compare_frame_identity(self.source, 5.123, 18.456, "fast")
