"""Metafile lookup and completion for the :doc command."""

from pathlib import Path
from types import SimpleNamespace

from plugins.cmd_doc import doc


def test_nearest_prefers_directory_and_extension_order(tmp_path):
    command = doc("doc TODO")
    expected = tmp_path / "doc" / "TODO.nou"
    expected.parent.mkdir()
    expected.touch()
    later = tmp_path / "docs" / "TODO.md"
    later.parent.mkdir()
    later.touch()

    assert command._nearest(str(tmp_path), "TODO", lambda p: Path(p).is_file()) == str(
        expected
    )


def test_execute_edits_missing_doc_in_nearest_existing_docs_dir(tmp_path):
    (tmp_path / "doc").mkdir()
    command = doc("doc README")
    selected = []
    fm = SimpleNamespace(
        thisdir=SimpleNamespace(path=str(tmp_path)),
        select_file=selected.append,
        move=lambda **kwargs: selected.append(kwargs),
        edit_file=selected.append,
    )
    command.fm = fm

    command.execute()

    missing = tmp_path / "doc" / "README.nou"
    assert selected == [str(missing)]
    assert missing.parent.is_dir()


def test_quantifier_suffixes_name_and_completion_lists_all_doc_kinds():
    command = doc("doc TODO", quantifier=3)
    assert command.tab(0)[0] == "doc ARCH"
    assert "doc TODO" in command.tab(0)
    assert command.arg(1) == "TODO"
