"""Diff frontend selection, placeholder expansion, and diagnostics."""

from types import SimpleNamespace
import pytest
from plugins.diff_frontend import _pick_selection, _is_cmp_list, df


def entry(path):
    return SimpleNamespace(path=path, is_directory=False)


def test_selection_supports_cursor_pair_and_marked_gliding_pair():
    a, b = entry("/a"), entry("/b")
    current = SimpleNamespace(thisfile=a, thisdir=SimpleNamespace(marked_items=[b]))
    target = SimpleNamespace(
        thisfile=entry("/x"), thisdir=SimpleNamespace(marked_items=[])
    )
    assert _pick_selection(current, target, False) == [b, a]


def test_cmp_list_recognizes_verbose_and_short_l():
    assert _is_cmp_list(["cmp", "-l", "a", "b"])
    assert _is_cmp_list(["cmp", "--verbose"])
    assert not _is_cmp_list(["cmp", "-s"])


def test_df_expands_paths_and_reports_bad_command():
    a, b = entry("/a"), entry("/b")
    tab = SimpleNamespace(thisfile=a, thisdir=SimpleNamespace(marked_items=[]))
    other = SimpleNamespace(thisfile=b, thisdir=SimpleNamespace(marked_items=[]))
    calls, notices = [], []
    fm = SimpleNamespace(
        tabs={1: tab, 2: other},
        current_tab=1,
        execute_command=lambda cmd, **kw: calls.append((cmd, kw)),
        notify=lambda *a, **kw: notices.append((a, kw)),
    )
    command = df("df cat %1 %2")
    command.fm = fm
    command.execute()
    assert calls[0][0] == ["cat", "/a", "/b"]
    bad = df("df 'unterminated")
    bad.fm = fm
    assert bad.execute() == 1
    assert "bad quoting" in notices[-1][0][0]
