"""Selection movement and symlink paste commands."""

import os
import shlex
from types import SimpleNamespace

from plugins import cmd_xfer


def test_mvsel_cuts_then_pastes_and_notifies():
    calls = []
    fm = SimpleNamespace(
        cut=lambda: calls.append("cut"),
        paste=lambda **kw: calls.append(kw),
        notify=calls.append,
    )
    cmd = cmd_xfer.mvsel("mvsel /destination")
    cmd.fm = fm
    cmd.execute()
    assert calls == ["cut", {"dest": "/destination"}, "/destination"]


def test_paste_flatlink_uses_custom_paste_flow(tmp_path, monkeypatch):
    source = tmp_path / "source"
    source.write_text("content")
    destination = tmp_path / "dest"
    destination.mkdir()
    item = SimpleNamespace(path=str(source))
    fm = SimpleNamespace(
        thistab=SimpleNamespace(path=str(destination)), copy_buffer=[item]
    )
    captured = []
    monkeypatch.setattr(
        cmd_xfer.pasteflow,
        "run_custom",
        lambda fm_arg, callback: captured.append((fm_arg, callback)),
    )
    cmd = cmd_xfer.paste_flatlink("paste_flatlink")
    cmd.fm = fm
    cmd.execute()
    assert captured[0][0] is fm
    captured[0][1](fm)
    link = destination / str(source).replace("/", "⁄")
    assert link.is_symlink() and link.resolve() == source


def test_link_orig_preserves_literal_special_characters_and_skips_duplicate(tmp_path):
    source = tmp_path / "data" / "clip $HOME.mp4"
    source.parent.mkdir()
    source.write_text("video")
    destination = tmp_path / "view"
    destination.mkdir()
    commands, notices, marks = [], [], []

    def execute_command(command):
        commands.append(command)
        args = shlex.split(command)
        assert args[:3] == ["ln", "-svt", str(destination)]
        target = args[-1]
        os.symlink(target, destination / source.name)

    entry = SimpleNamespace(path=str(source))
    fm = SimpleNamespace(
        get_macros=lambda: {"D": str(destination)},
        thistab=SimpleNamespace(get_selection=lambda: [entry]),
        execute_command=execute_command,
        mark_files=lambda **kw: marks.append(kw),
        notify=lambda *a, **kw: notices.append((a, kw)),
    )
    command = cmd_xfer.link_orig("link_orig")
    command.fm = fm
    command.execute()
    assert (destination / source.name).resolve() == source
    assert len(commands) == 1
    assert marks == [{"all": True, "val": False}]

    command.execute()
    assert len(commands) == 1
    assert "same target already exists" in notices[-1][0][0]


def test_paste_relink_reexpresses_relative_target_from_destination(
    tmp_path, monkeypatch
):
    original_dir = tmp_path / "original"
    original_dir.mkdir()
    source = original_dir / "movie.mp4"
    source.write_text("data")
    alias = original_dir / "alias.mp4"
    alias.symlink_to("movie.mp4")
    destination = tmp_path / "destination"
    destination.mkdir()
    item = SimpleNamespace(
        path=str(alias), dirname=str(original_dir), basename="alias.mp4"
    )
    fm = SimpleNamespace(
        thistab=SimpleNamespace(path=str(destination)),
        copy_buffer=[item],
        notify=lambda *_a, **_kw: None,
    )
    captured = []
    monkeypatch.setattr(
        cmd_xfer.pasteflow,
        "run_custom",
        lambda fm_arg, callback: captured.append((fm_arg, callback)),
    )
    command = cmd_xfer.paste_relink("paste_relink")
    command.fm = fm
    command.execute()
    captured[0][1](fm)
    assert (destination / "alias.mp4").is_symlink()
    assert (destination / "alias.mp4").resolve() == source


def test_paste_relink_reports_existing_destination_error(tmp_path, monkeypatch):
    source_dir = tmp_path / "src"
    source_dir.mkdir()
    link = source_dir / "link"
    link.symlink_to("target")
    destination = tmp_path / "dest"
    destination.mkdir()
    (destination / "link").write_text("collision")
    notices = []
    item = SimpleNamespace(path=str(link), dirname=str(source_dir), basename="link")
    fm = SimpleNamespace(
        thistab=SimpleNamespace(path=str(destination)),
        copy_buffer=[item],
        notify=lambda *a, **kw: notices.append((a, kw)),
    )
    captured = []
    monkeypatch.setattr(
        cmd_xfer.pasteflow,
        "run_custom",
        lambda fm_arg, callback: captured.append((fm_arg, callback)),
    )
    command = cmd_xfer.paste_relink("paste_relink")
    command.fm = fm
    command.execute()
    captured[0][1](fm)
    assert notices and notices[0][1]["bad"] is True
    assert "paste_relink" in notices[0][0][0]
