"""Tree-preserving search scope, flag validation, and layer usability."""

from types import SimpleNamespace

import pytest

from plugins import treefilter


def test_path_scope_uses_component_boundaries():
    assert treefilter._within("/root/a/file", "/root/a")
    assert treefilter._within("/root/a", "/root/a")
    assert not treefilter._within("/root/ab/file", "/root/a")


@pytest.mark.parametrize(
    ("tool", "tokens", "depth"),
    [
        ("fd", ["--max-depth", "2", "needle"], True),
        ("fd", ["-e", "mp4", "needle"], False),
        ("rg", ["--maxdepth=3", "needle"], True),
        ("rg", ["-i", "needle"], False),
    ],
)
def test_search_flags_preserve_valid_depth_and_pattern_options(tool, tokens, depth):
    assert treefilter._scan(tool, tokens) is depth


@pytest.mark.parametrize(
    ("tool", "flag"),
    [("fd", "--exec"), ("fd", "-0"), ("rg", "--json"), ("rg", "-h")],
)
def test_flags_that_break_result_parsing_are_rejected(tool, flag):
    with pytest.raises(ValueError, match="not supported"):
        treefilter._scan(tool, [flag])


def test_search_plan_prefers_marked_items_and_limits_result_scope(
    monkeypatch, tmp_path
):
    a = SimpleNamespace(path=str(tmp_path / "a"), basename="a", is_directory=False)
    b = SimpleNamespace(path=str(tmp_path / "b"), basename="b", is_directory=False)
    directory = SimpleNamespace(marked_items=[a], files=[b], files_all=[a, b])
    monkeypatch.setattr(treefilter.shutil, "which", lambda _tool: "/usr/bin/rg")
    fm = SimpleNamespace(thisdir=directory)

    jobs, names = treefilter._plan(fm, "rg", ["-i", "needle"])

    assert jobs[0][0][0] == "/usr/bin/rg"
    assert jobs[0][0][-1] == str(tmp_path / "a")
    assert names is None


def test_nested_sessions_release_only_the_requested_directory():
    root = "/tmp/treefilter"
    session = treefilter._Session(
        root=root,
        allowed={root, root + "/matched", root + "/matched/file"},
        full={root + "/matched"},
        label="needle",
    )

    assert treefilter._live(session, root)
    assert not treefilter._live(session, root + "/matched")
    assert treefilter._live(session, root + "/other")
    assert not session(SimpleNamespace(path=root + "/other"))
    session.released.add(root)
    assert not treefilter._live(session, root)
