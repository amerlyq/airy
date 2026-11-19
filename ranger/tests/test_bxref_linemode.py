"""Birth-time cross-reference line mode formatting."""

from types import SimpleNamespace

from plugins.bxref_linemode import BTimeXrefLinemode


def test_bxref_prefixes_encoded_mtime(monkeypatch):
    mode = BTimeXrefLinemode()
    monkeypatch.setattr(mode, "to_z85", lambda stamp: f"{int(stamp):08x}")
    file = SimpleNamespace(stat=SimpleNamespace(st_mtime=42.9))
    assert mode.infostring(file, None) == "⌇0000002a"


def test_z85_subprocess_receives_big_endian_seconds(monkeypatch):
    from plugins import bxref_linemode

    captured = {}

    def run(args, **kwargs):
        captured["args"] = args
        captured["input"] = kwargs["input"]
        return SimpleNamespace(stdout=b"abcde\n")

    monkeypatch.setattr("subprocess.run", run)
    assert BTimeXrefLinemode().to_z85(0x01020304) == "edcba"
    assert captured["input"] == b"\x01\x02\x03\x04"
