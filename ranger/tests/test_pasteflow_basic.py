"""Pytest coverage for plugin behavior that requires a fresh Ranger process."""

from pathlib import Path
import importlib

import pytest


@pytest.mark.integration
def test_pasteflow_basic(run_isolated_test_module):
    result = run_isolated_test_module(Path(__file__))
    assert result.returncode == 0, result.stdout


def _run_isolated_case():
    """Process-isolated basic pasteflow copy and cursor-selection scenario."""

    from plugins import pasteflow
    globals().update({key: value for key, value in vars(importlib.import_module("pasteflow_test_support")).items() if not key.startswith("__")})

    root = tempfile.mkdtemp()
    src = os.path.join(root, "src")
    dst = os.path.join(root, "dst")
    os.makedirs(src)
    os.makedirs(dst)
    for n in ("b.txt", "a.txt", "c.txt"):
        open(os.path.join(src, n), "w").write(n)
    open(os.path.join(dst, "z0.txt"), "w").write("old")
    open(os.path.join(dst, "a.txt"), "w").write("old")
    fm = make_fm(dst)
    d = fm.get_directory(dst)
    d.load_content(schedule=False)
    fm.thistab.thisdir = d
    fm.thistab.pathway = (d,)
    print("thisdir", fm.thisdir.path)
    sd = fm.get_directory(src)
    sd.load_content(schedule=False)
    fm.copy_buffer = {f for f in sd.files_all if f.basename in ("a.txt", "b.txt")}
    fm.do_cut = False
    fm.paste()
    pump(fm)
    print(
        "files",
        sorted(os.listdir(dst)),
        "cursor",
        fm.thisdir.pointer,
        fm.thisdir.files[fm.thisdir.pointer].basename,
    )
    print("notes", fm.notes)
    assert sorted(os.listdir(dst)) == ["a.txt", "a.txt_", "b.txt", "z0.txt"]
    assert fm.thisdir.files[fm.thisdir.pointer].basename == "a.txt_"
    assert not fm.notes


if __name__ == "__main__":
    _run_isolated_case()
