"""AVFS archive navigation falls back cleanly outside mount paths."""

from types import SimpleNamespace
from plugins import cmd_avfs


def test_archive_file_enters_mount_and_selects_mount_path(tmp_path, monkeypatch):
    mount = tmp_path / "avfs"
    mount.mkdir()
    monkeypatch.setattr(cmd_avfs, "AVFSDIR", str(mount))
    archive = SimpleNamespace(
        path="/data/a.zip", is_file=True, container=True, extension="zip"
    )
    calls = []
    fm = SimpleNamespace(
        thisfile=archive,
        select_file=calls.append,
        cd=calls.append,
        move=lambda **kw: calls.append(kw),
    )
    cmd_avfs.avfs_right("avfs_right").fm = fm
    cmd = cmd_avfs.avfs_right("avfs_right")
    cmd.fm = fm
    cmd.execute()
    mounted = str(mount) + "/data/a.zip"
    assert calls == [mounted, mounted + "#/"]


def test_non_archive_uses_native_right_move(tmp_path, monkeypatch):
    mount = tmp_path / "avfs"
    mount.mkdir()
    monkeypatch.setattr(cmd_avfs, "AVFSDIR", str(mount))
    calls = []
    fm = SimpleNamespace(
        thisfile=SimpleNamespace(
            path="/tmp/x", is_file=True, container=False, extension="txt"
        ),
        move=lambda **kw: calls.append(kw),
    )
    command = cmd_avfs.avfs_right("avfs_right")
    command.fm = fm
    command.execute()
    assert calls == [{"right": 1}]
