"""Filename, size, timestamp, permission, and link display modes."""

from types import SimpleNamespace

from plugins import linemodes


def test_size_modes_render_decimal_and_hex_and_reject_directories():
    file = SimpleNamespace(
        relative_path="clip.mp4", is_directory=False, stat=SimpleNamespace(st_size=31)
    )
    assert linemodes.BytesizeLinemode().infostring(file, None) == "31"
    assert linemodes.HexsizeLinemode().infostring(file, None) == "00001f"
    directory = SimpleNamespace(is_directory=True, stat=None)
    try:
        linemodes.BytesizeLinemode().infostring(directory, None)
    except NotImplementedError:
        pass
    else:
        raise AssertionError("directory byte size must be unsupported")


def test_link_mode_shows_relative_target_and_falls_back_on_read_error(
    tmp_path, monkeypatch
):
    target = tmp_path / "target"
    target.write_text("x")
    link = tmp_path / "link"
    link.symlink_to(target)
    file = SimpleNamespace(relative_path="link", is_link=True, path=str(link))
    assert "→ " + str(target) in linemodes.LinksLinemode().filetitle(file, None)
    monkeypatch.setattr(
        linemodes.os, "readlink", lambda _: (_ for _ in ()).throw(OSError())
    )
    assert linemodes.LinksLinemode().filetitle(file, None) == "link → ?"


def test_time_modes_format_timestamp_and_xperm_delegates():
    import time

    stamp = 1_700_000_000
    file = SimpleNamespace(
        relative_path="x",
        stat=SimpleNamespace(st_atime=stamp, st_ctime=stamp, st_mtime=stamp),
        get_permission_string=lambda: "rwx------",
    )
    expected = time.strftime("%Y-%m-%d %H:%M:%S", time.localtime(stamp))
    assert linemodes.ATimeLinemode().infostring(file, None) == expected
    assert linemodes.CTimeLinemode().infostring(file, None) == expected
    assert linemodes.MTimeLinemode().infostring(file, None) == expected
    assert linemodes.XPermLinemode().infostring(file, None) == "rwx------"
