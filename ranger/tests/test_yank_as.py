"""Path, glob, regex, split, and alias selection for :yank_as."""

from types import SimpleNamespace
from unittest.mock import patch

from plugins.yank_as import yank_as


def make_command(line):
    command = yank_as(line)
    command.fm = SimpleNamespace(
        thisfile=SimpleNamespace(
            path="/tmp/one-two_three.txt", relative_path="one-two_three.txt"
        ),
        thisdir=SimpleNamespace(path="/tmp"),
        thistab=SimpleNamespace(
            get_selection=lambda: [
                SimpleNamespace(relative_path="one.txt"),
                SimpleNamespace(relative_path="two.txt"),
            ]
        ),
    )
    return command


def test_named_sources_and_aliases_are_copied_verbatim():
    with patch("plugins.yank_as.subprocess.run") as run:
        make_command("yank_as name").execute()
        make_command("yank_as sel").execute()

    assert run.call_args_list[0].kwargs["input"] == b"one-two_three.txt"
    assert run.call_args_list[1].kwargs["input"] == b"one.txt\ntwo.txt"


def test_glob_regex_and_split_transform_only_the_requested_piece():
    with patch("plugins.yank_as.subprocess.run") as run:
        make_command("yank_as glob='-*'").execute()
        make_command("yank_as regex=^one").execute()
        make_command("yank_as split='-',1").execute()

    assert [call.kwargs["input"] for call in run.call_args_list] == [
        b"one",
        b"-two_three.txt",
        b"two_three.txt",
    ]


def test_invalid_split_index_is_visible_to_the_user():
    command = make_command("yank_as split='-',8")
    with patch("plugins.yank_as.subprocess.run"):
        try:
            command.execute()
        except IndexError:
            pass
        else:
            raise AssertionError("out-of-range split should be rejected")
