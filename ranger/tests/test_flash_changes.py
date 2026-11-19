"""Change flash stage, pending queues, and directory signatures."""

from plugins import flash_changes


def test_flash_stage_expires_and_advances(tmp_path):
    path = str(tmp_path / "changed")
    flash_changes._STATE.flashes[path] = 10.0
    assert flash_changes._stage(path, 9.95) == 3
    assert flash_changes._stage(path, 10.0) is None
    assert path not in flash_changes._STATE.flashes


def test_queue_merges_names_and_signature_tracks_files(tmp_path):
    (tmp_path / "one").write_text("a")
    flash_changes._STATE.pending.clear()
    flash_changes._queue(str(tmp_path), ["one"])
    flash_changes._queue(str(tmp_path), ["two"])
    assert flash_changes._STATE.pending[str(tmp_path)] == {"one", "two"}
    signature = flash_changes._signature(str(tmp_path))
    assert set(signature) == {"one"}
    assert len(signature["one"]) == 3
