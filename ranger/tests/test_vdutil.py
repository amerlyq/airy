"""Filesystem and symlink helpers shared by vdsym-related plugins."""

import os

from plugins import vdutil


def test_hops_follow_link_chains_and_keep_each_link_as_a_hop(tmp_path):
    target = tmp_path / "target"
    target.touch()
    second = tmp_path / "second"
    second.symlink_to(target)
    first = tmp_path / "first"
    first.symlink_to(second)

    assert list(vdutil._hops(str(first))) == [str(second), str(target)]
    assert vdutil._dangling(str(first)) is False


def test_broken_and_looped_symlinks_are_reported_as_dangling(tmp_path):
    missing = tmp_path / "missing-link"
    missing.symlink_to(tmp_path / "missing")
    one = tmp_path / "one"
    two = tmp_path / "two"
    one.symlink_to(two)
    two.symlink_to(one)

    assert vdutil._dangling(str(missing))
    assert vdutil._dangling(str(one))
    assert vdutil._gone(str(tmp_path / "missing"))


def test_replace_link_renames_alias_to_target_basename_and_preserves_target(tmp_path):
    view = tmp_path / "view"
    data = tmp_path / "data"
    view.mkdir()
    data.mkdir()
    target = data / "new-name.mp4"
    target.touch()
    alias = view / "old-name.mp4"
    alias.symlink_to("does-not-matter")

    assert vdutil.replace_link(str(alias), "../data/new-name.mp4", str(target)) is None

    replacement = view / "new-name.mp4"
    assert replacement.is_symlink()
    assert os.readlink(replacement) == "../data/new-name.mp4"
    assert not os.path.lexists(alias)


def test_replace_link_rejects_a_conflicting_destination(tmp_path):
    source = tmp_path / "alias"
    source.symlink_to("old-target")
    destination = tmp_path / "target"
    destination.write_text("ordinary file")

    message = vdutil.replace_link(str(source), "target", str(destination))

    assert message and "Collision" in message
    assert source.is_symlink()


def test_link_text_keeps_absolute_and_relative_spelling(tmp_path):
    view = tmp_path / "view"
    data = tmp_path / "data"
    view.mkdir()
    data.mkdir()
    link = view / "movie"
    link.symlink_to(data / "old.mp4")

    assert vdutil._link_text(
        str(link), str(data / "old.mp4"), str(data / "new.mp4"), ""
    ) == str(data / "new.mp4")
    link.unlink()
    link.symlink_to("../data/old.mp4")
    assert (
        vdutil._link_text(str(link), str(data / "old.mp4"), str(data / "new.mp4"), "")
        == "../data/new.mp4"
    )


def test_brief_caps_output_and_reports_remaining_count():
    assert vdutil._brief(["a", "b", "c", "d", "e"], 3) == "a | b | c +2"
