"""Linux statx birth-time sort key with cached fallback."""

import struct
from types import SimpleNamespace

from plugins import sort_birthtime


def test_statx_birthtime_is_cached_and_sort_key_is_descending(monkeypatch):
    buf = sort_birthtime._buf

    def statx(_dirfd, _path, _flags, _mask, output):
        struct.pack_into("<I", output, 0, 0x800)
        struct.pack_into("<qI", output, 80, 123, 500_000_000)
        return 0

    monkeypatch.setattr(sort_birthtime, "_statx", statx)
    file_obj = SimpleNamespace(path="/tmp/new", stat=SimpleNamespace(st_mtime=1))

    assert sort_birthtime.sort_by_birthtime(file_obj) == -123.5
    assert sort_birthtime.sort_by_birthtime(file_obj) == -123.5


def test_statx_falls_back_to_mtime_when_birthtime_is_unavailable(monkeypatch):
    monkeypatch.setattr(sort_birthtime, "_statx", lambda *_args: -1)
    file_obj = SimpleNamespace(
        path="/proc/self/stat", stat=SimpleNamespace(st_mtime=42)
    )

    assert sort_birthtime.sort_by_birthtime(file_obj) == -42
    assert file_obj._btime == 42
