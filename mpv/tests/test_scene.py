"""Scene seeking against controlled cuts plus deterministic cancellation tests."""
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
DRIVER = ROOT / "mpv/tests/scene_driver.lua"
LUA = shutil.which("lua") or shutil.which("luajit")
FFMPEG = shutil.which("ffmpeg")


def run(args):
    result = subprocess.run(list(map(str, args)), capture_output=True, text=True, timeout=60)
    if result.returncode:
        raise AssertionError(result.stderr)
    return result.stdout


@unittest.skipUnless(LUA, "Lua required")
class SceneLifecycleTests(unittest.TestCase):
    def test_cancellation_and_direction(self):
        run([LUA, DRIVER, "lifecycle", ROOT / "mpv/scripts/sceneseeker.lua"])


@unittest.skipUnless(LUA and FFMPEG, "Lua and FFmpeg required")
class SceneMediaTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="scene-tests-")
        cls.source = Path(cls.temp.name) / "scenes with 'quote.mp4"
        args = [FFMPEG, "-v", "error", "-nostdin"]
        for color, duration in (("black", 2), ("white", 16), ("black", 8), ("white", 14)):
            args += ["-f", "lavfi", "-i", f"color={color}:s=160x90:r=10:d={duration}"]
        args += ["-filter_complex", "[0:v][1:v][2:v][3:v]concat=n=4:v=1:a=0",
                 "-c:v", "mpeg4", "-g", "1000", "-bf", "2", cls.source]
        run(args)

    @classmethod
    def tearDownClass(cls):
        cls.temp.cleanup()

    def scan(self, position, direction, expected, source=None):
        output = run([LUA, DRIVER, "media", source or self.source, position, direction, 40])
        found, windows = output.split()
        self.assertAlmostEqual(float(found), expected, places=4, msg=output)
        return int(windows)

    def test_forward_and_current_boundary(self):
        for position, expected in ((0, 2), (1.95, 2), (2, 18), (18, 26), (26, 40)):
            with self.subTest(position=position):
                self.scan(position, "forward", expected)

    def test_backward_nearest_and_window_seams(self):
        for position, expected in ((35, 26), (26, 18), (24, 18), (18, 2), (2, 0)):
            with self.subTest(position=position):
                self.scan(position, "backward", expected)

    def test_long_scene_continues(self):
        self.assertGreater(self.scan(3, "forward", 18), 1)
        self.assertGreater(self.scan(17, "backward", 2), 1)

    def test_nonzero_source_timestamps(self):
        source = Path(self.temp.name) / "offset.mp4"
        run([FFMPEG, "-v", "error", "-i", self.source, "-c", "copy",
             "-output_ts_offset", "5", source])
        self.scan(3, "forward", 18, source)
        self.scan(24, "backward", 18, source)

    def test_variable_frame_rate(self):
        source = Path(self.temp.name) / "vfr.mkv"
        run([FFMPEG, "-v", "error", "-i", self.source,
             "-vf", "select='if(lt(t,18),not(mod(n,2)),not(mod(n,3)))'",
             "-fps_mode", "vfr", "-c:v", "mpeg4", source])
        self.scan(3, "forward", 18, source)
        self.scan(24, "backward", 18, source)
