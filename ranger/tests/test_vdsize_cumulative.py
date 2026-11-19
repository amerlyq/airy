"""Recursive size modes, cycle safety, codec filters, and directory-cache reuse."""

import os
from types import SimpleNamespace

import pytest

from plugins import vdsize_cumulative as dcsize


def test_file_and_all_modes_count_symlinks_as_documented(tmp_path, monkeypatch):
    root = tmp_path / "root"
    root.mkdir()
    regular = root / "one.bin"
    regular.write_bytes(b"abc")
    link = root / "link.bin"
    link.symlink_to(regular)
    broken = root / "broken.bin"
    broken.symlink_to(root / "absent")
    monkeypatch.setattr(dcsize, "SIZES", {mode: {} for mode in dcsize.MODES})
    monkeypatch.setattr(dcsize.vdprobe, "_dmem", {})

    assert dcsize._tree(str(root), "file") == (1, 3)
    assert dcsize._tree(str(root), "all") == (3, 3 + 3 + os.lstat(broken).st_size)


def test_all_mode_descends_linked_directories_without_cycles(tmp_path, monkeypatch):
    root = tmp_path / "root"
    child = root / "child"
    child.mkdir(parents=True)
    (child / "payload").write_bytes(b"four")
    (child / "loop").symlink_to(root, target_is_directory=True)
    (root / "alias").symlink_to(child, target_is_directory=True)
    monkeypatch.setattr(dcsize, "SIZES", {mode: {} for mode in dcsize.MODES})
    monkeypatch.setattr(dcsize.vdprobe, "_dmem", {})

    assert dcsize._tree(str(root), "all") == (1, 4)


def test_codec_spec_is_case_insensitive_and_supports_exclusions():
    old = dcsize.SPEC
    try:
        dcsize.SPEC = dcsize._parse_spec("hevc,!avc")
        assert dcsize._match("HEVC")
        assert not dcsize._match("AVC")
        assert not dcsize._match("")
        assert dcsize._codec_label() == "*hevc,!avc"
    finally:
        dcsize.SPEC = old


def test_video_filter_uses_cached_matching_result(tmp_path, monkeypatch):
    path = tmp_path / "clip.mp4"
    path.write_bytes(b"clip")
    old_sizes = dcsize.SIZES
    try:
        dcsize.SIZES = {mode: {} for mode in dcsize.MODES}
        dcsize.SPEC = (frozenset({"av1"}), frozenset())
        monkeypatch.setattr(dcsize, "_tree", lambda *_args: (1, 4))
        filt = dcsize.DcFilter("video")
        file_entry = SimpleNamespace(is_directory=False, path=str(path))
        assert filt(file_entry)
    finally:
        dcsize.SIZES = old_sizes


@pytest.mark.benchmark
def test_cached_directory_totals_avoid_a_second_walk(tmp_path, monkeypatch):
    root = tmp_path / "many"
    root.mkdir()
    for index in range(2_000):
        (root / f"{index}.dat").touch()
    monkeypatch.setattr(dcsize.vdprobe, "_dmem", {})
    monkeypatch.setattr(dcsize, "SIZES", {mode: {} for mode in dcsize.MODES})
    monkeypatch.setattr(dcsize, "_FRESH", False)
    monkeypatch.setattr(dcsize, "_DIR_HITS", 0)
    monkeypatch.setattr(dcsize, "_DIR_SCANS", 0)

    first = dcsize._tree(str(root), "file")
    second = dcsize._tree(str(root), "file")

    assert first == second == (2_000, 0)
    assert dcsize._DIR_SCANS == 1
    assert dcsize._DIR_HITS == 1
