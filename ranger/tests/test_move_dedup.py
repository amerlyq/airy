"""Byte comparison and empty-directory pruning helpers."""

from pathlib import Path
from types import SimpleNamespace
import pytest
from plugins.move_dedup import move_dedup


def test_file_comparison_handles_equal_unequal_and_missing_files(tmp_path):
    a, b, c = (tmp_path / name for name in ("a", "b", "c"))
    a.write_bytes(b"same")
    b.write_bytes(b"same")
    c.write_bytes(b"else")
    assert move_dedup._files_identical(a, b, bufsize=2)
    assert not move_dedup._files_identical(a, c)
    assert not move_dedup._files_identical(a, tmp_path / "missing")


def test_empty_nested_directories_are_pruned_bottom_up(tmp_path):
    root = tmp_path / "source"
    nested = root / "a" / "b"
    nested.mkdir(parents=True)
    (nested / "file").write_text("x")
    (nested / "file").unlink()
    move_dedup._prune_empty_dirs(root)
    assert root.is_dir()
    assert not (root / "a").exists()


@pytest.mark.integration
def test_move_dedup_executes_unique_duplicate_and_conflict_phases(tmp_path):
    src = tmp_path / "src"
    dst = tmp_path / "dst"
    src.mkdir()
    dst.mkdir()
    (src / "unique").write_text("new")
    (src / "same").write_text("same")
    (dst / "same").write_text("same")
    (src / "conflict").write_text("incoming")
    (dst / "conflict").write_text("existing")
    loaded, notices = [], []
    tabs = {
        1: SimpleNamespace(path=str(src), load_content=lambda: loaded.append("src")),
        2: SimpleNamespace(path=str(dst), load_content=lambda: loaded.append("dst")),
    }
    fm = SimpleNamespace(
        thisdir=tabs[1], tabs=tabs, current_tab=1, notify=notices.append
    )
    command = move_dedup("move_dedup")
    command.fm = fm
    command.execute()
    assert (dst / "unique").read_text() == "new"
    assert not (src / "same").exists()
    assert (dst / "conflict_").read_text() == "incoming"
    assert (dst / "conflict_1").read_text() == "existing"
    assert loaded == ["src", "src", "dst"]
