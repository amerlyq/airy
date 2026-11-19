"""Directory jump commands resolve paths and preserve expected selections."""

from types import SimpleNamespace
from plugins.cmd_cd import cda, cd_realdir


def test_cda_resolves_relative_path_and_selects_file(tmp_path):
    target = tmp_path / "file.txt"
    target.write_text("x")
    calls = []
    fm = SimpleNamespace(
        thisdir=SimpleNamespace(path=str(tmp_path)),
        cd=lambda p: calls.append(("cd", p)),
        select_file=lambda p: calls.append(("select", p)),
    )
    cmd = cda("cda file.txt:12:4:")
    cmd.fm = fm
    cmd.execute()
    assert calls == [("select", str(target))]


def test_cd_realdir_restores_selected_basename_when_loaded(tmp_path):
    target_dir = tmp_path / "real"
    target_dir.mkdir()
    selected = SimpleNamespace(basename="chosen", path=str(target_dir / "chosen"))
    directory = SimpleNamespace(
        path=str(target_dir),
        files=[selected],
        files_all=[selected],
        loading=False,
        move_to_obj=lambda p: moved.append(p),
    )
    moved = []
    calls = []
    fm = SimpleNamespace(
        thisfile=SimpleNamespace(basename="chosen"),
        get_directory=lambda p: directory,
        signal_bind=lambda *a: "handler",
        signal_unbind=lambda h: None,
        cd=lambda p: (calls.append(p), setattr(fm, "thisdir", directory)),
        thisdir=SimpleNamespace(path="old"),
    )
    cmd = cd_realdir("cd_realdir " + str(target_dir))
    cmd.fm = fm
    cmd.execute()
    assert calls == [str(target_dir)]
    assert moved == [selected.path]
