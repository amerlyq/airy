"""Shared filesystem and date helpers used by Ranger commands."""

from datetime import datetime
from os import path

from plugins import base_util


def test_today_date_applies_the_configured_hour_boundary():
    now = datetime.now().astimezone()
    assert base_util.today_date(0) == now.strftime("%Y-%m-%d")


def test_tmpfile_uses_ranger_override_and_creates_directory(tmp_path, monkeypatch):
    runtime = tmp_path / "runtime"
    override = runtime / "ranger"
    runtime.mkdir()
    monkeypatch.setenv("RANGER_TMPDIR", str(override))
    monkeypatch.setenv("XDG_RUNTIME_DIR", str(tmp_path / "ignored"))

    result = base_util.tmpfile("cwd")

    assert result == str(override / "cwd")
    assert override.is_dir()
    assert path.dirname(result) == str(override)


def test_tmpfile_defaults_to_runtime_ranger_directory(tmp_path, monkeypatch):
    monkeypatch.delenv("RANGER_TMPDIR", raising=False)
    monkeypatch.setenv("XDG_RUNTIME_DIR", str(tmp_path))

    assert base_util.tmpfile("buffer") == str(tmp_path / "ranger" / "buffer")
