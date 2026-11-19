"""Pytest configuration and isolated-process fixture for plugin integration tests."""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]


@pytest.fixture
def run_isolated_test_module():
    """Run a pytest module's isolated case body in a fresh Python process."""

    def run(script: Path) -> subprocess.CompletedProcess[str]:
        with tempfile.TemporaryDirectory(prefix="ranger-plugin-test-") as scratch:
            env = os.environ.copy()
            env.update(TMPDIR=scratch, PYTHONDONTWRITEBYTECODE="1")
            env["PYTHONPATH"] = os.pathsep.join((str(ROOT), env.get("PYTHONPATH", "")))
            return subprocess.run(
                [sys.executable, str(script)],
                cwd=ROOT,
                env=env,
                text=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                timeout=180,
            )

    return run
