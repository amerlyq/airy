"""Profile report generation and latest-profile discovery."""

import cProfile
import os
from pathlib import Path
from plugins import rprofile


def test_latest_profile_ignores_non_profile_files(tmp_path, monkeypatch):
    monkeypatch.setattr(rprofile, "_profile_dir", lambda: str(tmp_path))
    (tmp_path / "old.prof").write_bytes(b"x")
    (tmp_path / "notes.txt").write_text("x")
    (tmp_path / "new.prof").write_bytes(b"x")
    os.utime(tmp_path / "old.prof", (1, 1))
    os.utime(tmp_path / "new.prof", (2, 2))
    assert Path(rprofile._latest_profile()).name == "new.prof"


def test_profile_report_has_top_time_tables(tmp_path):
    prof = tmp_path / "sample.prof"
    profiler = cProfile.Profile()
    profiler.runcall(sum, range(10))
    profiler.dump_stats(prof)
    report = rprofile._markdown_report(str(prof), limit=3)
    assert "# Ranger performance profile" in report
    assert "Top 3 by cumulative time" in report
    assert "Top 3 by self time" in report
