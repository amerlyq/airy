"""Scaffold startup and commands are isolated from the user's home directory."""

import os
import subprocess
import sys
import pytest


@pytest.mark.integration
def test_scaffold_import_and_add_command_use_home_scoped_state(tmp_path):
    home = tmp_path / "home"
    home.mkdir()
    env = os.environ.copy()
    env["HOME"] = str(home)
    env["PYTHONPATH"] = os.pathsep.join(
        [os.getcwd(), os.path.join(os.getcwd(), "plugins"), env.get("PYTHONPATH", "")]
    )
    code = """
from types import SimpleNamespace
from plugins import scaffold
assert scaffold.TARGET_PATH.startswith(__import__('os').environ['HOME'])
entry = SimpleNamespace(path='/project/src')
entry2 = SimpleNamespace(path='/project/src2')
selected = [entry]
fm = SimpleNamespace(thistab=SimpleNamespace(get_selection=lambda: selected))
command = scaffold.scaffold_add('scaffold_add')
command.fm = fm
command.execute()
assert '/project/src' in open(scaffold.TARGET_PATH).read()
assert '/project/src' in __import__('ranger').scaffold_paths
selected[:] = [entry2]
second = scaffold.scaffold_add('scaffold_add 2')
second.fm = fm
second.execute()
assert '/project/src2' in __import__('ranger').scaffold_paths2

from ranger.container.directory import Directory
sort_key = Directory.sort_dict['natural'](SimpleNamespace(path='/project/src', basename_natural=['src']))
assert sort_key[:2] == [('', 0), ('', 0)]
sort_key2 = Directory.sort_dict['natural'](SimpleNamespace(path='/project/src2', basename_natural=['src2']))
assert sort_key2[:2] == [('', 0), ('', 1)]

import ranger.gui.widgets.browsercolumn as browsercolumn
drawn, colors = browsercolumn.hook_before_drawing(entry, [])
assert drawn is entry and 'scaffold' in colors
entry.path = '/project/src2'
drawn, colors = browsercolumn.hook_before_drawing(entry, [])
assert 'scaffold2' in colors

entry.path = '/project/src'
selected[:] = [entry, entry2]
remove = scaffold.scaffold_remove('scaffold_remove')
remove.fm = fm
remove.execute()
assert '/project/src' not in __import__('ranger').scaffold_paths
assert '/project/src' not in __import__('ranger').scaffold_paths2
assert '/project/src2' not in __import__('ranger').scaffold_paths2
"""
    result = subprocess.run(
        [sys.executable, "-c", code], env=env, capture_output=True, text=True
    )
    assert result.returncode == 0, result.stderr
    assert (home / ".local/share/ranger/scaffolds").is_file()
