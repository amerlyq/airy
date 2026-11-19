"""xattr command validates modifiers and delegates changes to chattr."""

from types import SimpleNamespace
from plugins.xattr_commands import xattr


def test_xattr_valid_mode_calls_chattr_with_macro_expanded_files():
    calls = []
    fm = SimpleNamespace(
        execute_command=calls.append,
        substitute_macros=lambda p, escape=False: "/expanded/" + p,
    )
    command = xattr("xattr +i file")
    command.fm = fm
    command.execute()
    assert calls == [["chattr", "+i", "/expanded/file"]]


def test_invalid_attribute_notifies_without_running_command():
    notices = []
    fm = SimpleNamespace(
        notify=lambda *a, **kw: notices.append((a, kw)), execute_command=lambda _: None
    )
    command = xattr("xattr +z file")
    command.fm = fm
    command.execute()
    assert "Wrong xattr value" in notices[0][0][0]
