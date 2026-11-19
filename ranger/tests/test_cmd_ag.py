"""ripgrep command construction and recursive temporary filtering."""

import re
from types import SimpleNamespace

from plugins.cmd_ag import ag


def test_command_builds_safe_rg_arguments_for_patterns_and_marked_paths():
    command = ag("ag -f 'two words'")
    command.fm = SimpleNamespace(
        thisdir=SimpleNamespace(
            marked_items=[SimpleNamespace(relative_path="dir/a file.txt")],
            files=[],
            files_all=[],
            temporary_filter=None,
        )
    )

    cmd, flags = command._choose()

    assert flags == "-p"
    assert "--hidden" in cmd
    assert "two words" in cmd
    assert "dir/a file.txt" in cmd


def test_search_filter_escapes_names_and_recurses_into_directories():
    grandchildren = []
    child = SimpleNamespace(
        is_directory=True,
        files_all=grandchildren,
        temporary_filter=None,
        refilter=lambda: None,
    )
    root = SimpleNamespace(
        is_directory=True,
        files_all=[child],
        temporary_filter=None,
        refilter=lambda: None,
    )
    command = ag("ag -r needle")

    command._filter(["a+b.txt"], root)

    assert root.temporary_filter.fullmatch("a+b.txt")
    assert not root.temporary_filter.fullmatch("aaab.txt")
    assert child.temporary_filter is not None
    assert child.temporary_filter.fullmatch("a+b.txt")


def test_filter_no_matches_does_not_hide_the_directory():
    directory = SimpleNamespace(temporary_filter=None, refilter=lambda: None)
    ag("ag -r nope")._filter([], directory)
    assert directory.temporary_filter is None
