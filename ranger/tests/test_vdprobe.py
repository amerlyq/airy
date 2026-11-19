"""Media probing, inode cache behavior, batch lookup, and API sentinels."""

from types import SimpleNamespace
from unittest.mock import Mock

from plugins import vdprobe


def test_lookup_uses_native_probe_then_memoizes_result(tmp_path, monkeypatch):
    media = tmp_path / "sample.mp4"
    media.write_bytes(b"not really media; probe mocked")
    stat = media.stat()
    monkeypatch.setattr(vdprobe, "_mem", {})
    monkeypatch.setattr(
        vdprobe._media_store,
        "get_with_status",
        lambda _stat: (None, False),
    )
    monkeypatch.setattr(vdprobe, "probe_path", lambda _path: (1234, "AV1"))
    monkeypatch.setattr(vdprobe, "_duration_index_put", lambda *_args: None)
    monkeypatch.setattr(
        vdprobe,
        "_put",
        lambda ino, mt, size, result, *_args: vdprobe._mem.__setitem__(
            ino, (mt, size, result)
        ),
    )
    vdprobe.stats[:] = [0, 0]

    assert vdprobe.lookup(str(media), stat) == ((1234, "AV1"), False)
    assert vdprobe.lookup(str(media), stat) == ((1234, "AV1"), True)
    assert vdprobe.stats == [1, 1]
    assert vdprobe.duration(str(media), stat) == 1234
    assert vdprobe.codec(str(media), stat) == "AV1"


def test_lookup_skips_missing_nonregular_and_unrecognized_files(tmp_path, monkeypatch):
    directory = tmp_path / "folder"
    directory.mkdir()
    monkeypatch.setattr(vdprobe, "probe_path", lambda _path: None)

    assert vdprobe.lookup(str(tmp_path / "missing")) == (None, True)
    assert vdprobe.lookup(str(directory)) == (None, True)


def test_many_batches_cache_reads_and_omits_missing_paths(tmp_path, monkeypatch):
    files = [tmp_path / f"{index}.mp4" for index in range(20)]
    for file in files:
        file.touch()
    monkeypatch.setattr(vdprobe, "_mem", {})
    store = SimpleNamespace(get_many_records=Mock(return_value={}))
    monkeypatch.setattr(vdprobe, "_media_store", store)
    monkeypatch.setattr(vdprobe, "probe_path", lambda _path: (900, "H264"))
    monkeypatch.setattr(vdprobe, "_duration_index_put", lambda *_args: None)
    monkeypatch.setattr(
        vdprobe,
        "_put",
        lambda ino, mt, size, result, *_args: vdprobe._mem.__setitem__(
            ino, (mt, size, result)
        ),
    )

    result = vdprobe.many([str(file) for file in files] + [str(tmp_path / "gone")])

    assert len(result) == len(files)
    assert set(result.values()) == {(900, "H264")}
    store.get_many_records.assert_called_once()


def test_failed_fallback_is_session_memoized_without_reprobing(tmp_path, monkeypatch):
    media = tmp_path / "unknown.bin"
    media.write_bytes(b"unknown")
    monkeypatch.setattr(vdprobe, "_mem", {})
    monkeypatch.setattr(
        vdprobe._media_store, "get_with_status", lambda _st: (None, False)
    )
    monkeypatch.setattr(vdprobe, "probe_path", lambda _path: False)
    fallback = Mock(return_value=False)
    monkeypatch.setattr(vdprobe, "_mediainfo_one", fallback)

    assert vdprobe.lookup(str(media))[0] is None
    assert vdprobe.lookup(str(media))[0] is None
    fallback.assert_called_once_with(str(media))
