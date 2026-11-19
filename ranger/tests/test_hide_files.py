"""Inactive hide-files experiment filters only the configured system paths."""

import os
import subprocess
import sys
import pytest


@pytest.mark.integration
def test_hide_files_respects_show_hidden_and_delegates_other_paths():
    code = """
from types import SimpleNamespace
import ranger.container.directory as directory
directory.accept_file = lambda file, filters: ('original', file.path, filters)
from plugins.unused import hide_files as plugin
system_path = plugin.HIDE_FILES[0]
file = SimpleNamespace(path=system_path, fm=SimpleNamespace(settings=SimpleNamespace(show_hidden=False)))
assert plugin.custom_accept_file(file, None) is False
file.fm.settings.show_hidden = True
assert plugin.custom_accept_file(file, None) == ('original', system_path, None)
file.path = '/unrelated/file'
assert plugin.custom_accept_file(file, 'filter') == ('original', file.path, 'filter')
"""
    env = os.environ.copy()
    env["PYTHONPATH"] = os.pathsep.join(
        [os.getcwd(), os.path.join(os.getcwd(), "plugins"), env.get("PYTHONPATH", "")]
    )
    result = subprocess.run(
        [sys.executable, "-c", code], env=env, capture_output=True, text=True
    )
    assert result.returncode == 0, result.stderr
