"""Console, edit, and mkdir usability behavior."""

from types import SimpleNamespace
from plugins.cmd_cli import console, edit, mkdir, touch


def test_console_position_flag_and_history_quantifier():
    calls = []
    cmd = console("console -p4 open")
    cmd.fm = SimpleNamespace(open_console=lambda *a, **kw: calls.append((a, kw)))
    cmd.execute()
    assert calls == [(("open",), {"position": 4})]
    cmd = console("console")
    cmd.quantifier = 2
    cmd.fm = SimpleNamespace(
        open_console=lambda *a, **kw: calls.append((a, kw)),
        ui=SimpleNamespace(
            console=SimpleNamespace(history_move=lambda n: calls.append(n))
        ),
    )
    cmd.execute()
    assert calls[-1] == -2


def test_edit_defaults_to_cursor_file_and_preserves_argument():
    opened = []
    fm = SimpleNamespace(
        thisfile=SimpleNamespace(path="/tmp/current"), edit_file=opened.append
    )
    edit("edit").fm = fm
    cmd = edit("edit")
    cmd.fm = fm
    cmd.execute()
    assert opened == ["/tmp/current"]
    cmd = edit("edit 'two words'")
    cmd.fm = fm
    cmd.execute()
    assert opened[-1] == "'two words'"


def test_touch_creates_nested_parent_and_reports_existing_path(tmp_path, monkeypatch):
    from plugins import cmd_cli

    monkeypatch.setattr(
        cmd_cli.pasteflow, "run_custom", lambda fm, callback: callback(fm)
    )
    notices = []
    fm = SimpleNamespace(
        thisdir=SimpleNamespace(path=str(tmp_path)),
        notify=lambda *a, **kw: notices.append((a, kw)),
    )
    cmd = touch("touch nested/new.txt")
    cmd.fm = fm
    cmd.execute()
    assert (tmp_path / "nested/new.txt").is_file()
    cmd.execute()
    assert notices and notices[0][1]["bad"]


def test_mkdir_uses_custom_paste_completion_path(tmp_path, monkeypatch):
    from plugins import cmd_cli

    monkeypatch.setattr(
        cmd_cli.pasteflow, "run_custom", lambda fm, callback: callback(fm)
    )
    fm = SimpleNamespace(
        thisdir=SimpleNamespace(path=str(tmp_path)), notify=lambda *a, **kw: None
    )
    command = mkdir("mkdir new/deep")
    command.fm = fm
    command.execute()
    assert (tmp_path / "new/deep").is_dir()
