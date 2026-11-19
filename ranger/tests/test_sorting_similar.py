"""Filename suffix sort keys and filesystem change-time sorting."""

from types import SimpleNamespace

import pytest

from plugins import sorting_similar


@pytest.mark.parametrize(
    ("name", "separator", "longest", "expected"),
    [
        ("movie-a-b.mp4", "-", False, "b.mp4"),
        ("movie-a-b.mp4", "-", True, "a-b.mp4"),
        ("take_01_final", "_", False, "final"),
        ("plain", "-", False, ""),
    ],
)
def test_suffix_key_extracts_last_or_first_segment(name, separator, longest, expected):
    file_obj = SimpleNamespace(relative_path=name)
    assert sorting_similar.sort_suffix(file_obj, separator, longest) == expected


def test_lctime_sort_handles_deleted_files_without_throwing(monkeypatch):
    monkeypatch.setattr(
        sorting_similar.os,
        "lstat",
        lambda _path: (_ for _ in ()).throw(FileNotFoundError()),
    )
    assert sorting_similar.lctime_sort(SimpleNamespace(path="/gone")) < -1e9
