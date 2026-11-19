"""Progress-counter updates and clipboard name swapping."""

from types import SimpleNamespace

from plugins.cmd_rename import nrenum, rename_clipboard


def test_nrenum_advances_ready_and_flips_complete_state_marker():
    command = nrenum("nrenum 2")
    calls = []
    command.fm = SimpleNamespace(
        thisfile=SimpleNamespace(relative_path="job{5@3}"),
        execute_console=calls.append,
    )

    command.execute()

    assert calls == ["rename job{5@5}"]


def test_nrenum_total_mode_and_quantifier_are_applied():
    command = nrenum("nrenum -t 4", quantifier=2)
    calls = []
    command.fm = SimpleNamespace(
        thisfile=SimpleNamespace(relative_path="job{5#2}"),
        execute_console=calls.append,
    )

    command.execute()

    assert calls == ["rename job{13#2}"]


def test_rename_clipboard_swaps_names_and_escapes_command_macro():
    clipboard = [".new%name"]
    calls = []
    command = rename_clipboard("rename_clip")
    command.fm = SimpleNamespace(
        get_clipboard=lambda: clipboard[0],
        set_clipboard=lambda value: clipboard.__setitem__(0, value.decode()),
        thisfile=SimpleNamespace(basename="old.mp4"),
        execute_console=calls.append,
    )

    command.execute()

    assert clipboard == ["old.mp4"]
    assert calls == ["rename .new%%name"]
