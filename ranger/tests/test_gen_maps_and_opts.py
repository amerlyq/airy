"""Startup theme and user path-map generation behavior."""

from types import SimpleNamespace
from plugins import gen_maps_and_opts


def test_theme_falls_back_without_256_color_terminal(monkeypatch, tmp_path):
    monkeypatch.setenv("TERM", "xterm")
    monkeypatch.setattr(
        gen_maps_and_opts.os.path, "expanduser", lambda p: str(tmp_path / "theme")
    )
    (tmp_path / "theme").write_text("light\n")
    fm = SimpleNamespace(confpath=lambda p: p)
    assert gen_maps_and_opts.get_colorscheme(fm) == "default"
    monkeypatch.setenv("TERM", "xterm-256color")
    assert gen_maps_and_opts.get_colorscheme(fm) == "solarized"


def test_aura_maps_are_sorted_and_comments_ignored(monkeypatch, tmp_path):
    f = tmp_path / "paths"
    f.write_text("z /last\na /first # comment\nignored\n")
    monkeypatch.setattr(gen_maps_and_opts, "old_hook_init", lambda fm: None)
    # The production path is fixed; confpath maps it to this temporary file.
    calls = []
    fm = SimpleNamespace(
        confpath=lambda _: str(f),
        execute_console=calls.append,
        notify=lambda *a, **kw: None,
    )
    gen_maps_and_opts.aura_pathes(fm)
    assert calls == ["map a cda /first", "map z cda /last"]
