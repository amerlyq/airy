"""Zsh alias command forwards flags and quotes shell arguments."""

from types import SimpleNamespace
from plugins.zsh_aliases import zs


def test_zs_quotes_command_and_preserves_shell_flags():
    calls = []
    command = zs("zs -p -w git status --short")
    command.fm = SimpleNamespace(execute_console=calls.append)
    command.execute()
    assert calls[0].startswith("shell -p -w zsh -c ")
    assert "'git status --short'" in calls[0]


def test_empty_command_is_noop():
    calls = []
    command = zs("zs")
    command.fm = SimpleNamespace(execute_console=calls.append)
    command.execute()
    assert calls == []
