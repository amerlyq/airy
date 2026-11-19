"""Tests for the inode, directory, tag, and path stores in plugins/inocache.py."""

import os

from plugins import inocache


def test_file_store_persists_by_inode_and_invalidates_edits(tmp_path):
    data = tmp_path / "data"
    cache = tmp_path / "cache"
    data.mkdir()
    original = data / "sample.bin"
    original.write_text("first")

    store = inocache.Store("fingerprints", 1, "file", str(cache))
    original_stat = original.stat()
    store.put(original_stat, ("hash", 42))
    store.flush()

    reopened = inocache.Store("fingerprints", 1, "file", str(cache))
    assert reopened.get(original_stat) == ("hash", 42)

    renamed = data / "renamed.bin"
    original.rename(renamed)
    assert reopened.get(renamed.stat()) == ("hash", 42)

    renamed.write_text("changed contents")
    assert reopened.get(renamed.stat()) is None
    assert reopened.get_many([renamed.stat()]) == {}


def test_store_validation_modes_and_independent_versions(tmp_path):
    data = tmp_path / "data"
    cache = tmp_path / "cache"
    data.mkdir()
    file_path = data / "tagged.bin"
    file_path.write_text("one")

    stat = file_path.stat()
    tags = inocache.Store("tags", 1, "none", str(cache))
    tags.put(stat, {"labels": ["keep"]})
    tags.flush()

    visited = inocache.Store("visited", 1, "path", str(cache))
    visited.put("/some/directory", True)
    visited.flush()

    assert inocache.Store("tags", 1, "none", str(cache)).get(file_path.stat()) == {
        "labels": ["keep"]
    }
    assert inocache.Store("visited", 1, "path", str(cache)).get(
        "/some/directory"
    ) is True
    assert inocache.Store("visited", 1, "path", str(cache)).get("/other") is None

    newer_version = inocache.Store("tags", 2, "none", str(cache))
    assert newer_version.get(stat) is None
    assert inocache.Store("visited", 1, "path", str(cache)).get(
        "/some/directory"
    ) is True


def test_directory_store_invalidates_when_directory_changes(tmp_path):
    data = tmp_path / "data"
    cache = tmp_path / "cache"
    data.mkdir()
    (data / "first").touch()

    store = inocache.Store("directory_totals", 1, "dir", str(cache))
    directory_stat = data.stat()
    store.put(directory_stat, [1, 2])
    store.flush()
    reopened = inocache.Store("directory_totals", 1, "dir", str(cache))

    assert reopened.get(data.stat()) == [1, 2]
    (data / "second").touch()
    assert reopened.get(data.stat()) is None
