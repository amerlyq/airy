"""Pytest coverage for plugin behavior that requires a fresh Ranger process."""

from pathlib import Path
import importlib

import pytest


@pytest.mark.integration
def test_pasteflow_ui_refresh(run_isolated_test_module):
    result = run_isolated_test_module(Path(__file__))
    assert result.returncode == 0, result.stdout


def _run_isolated_case():
    """Process-isolated pasteflow UI refresh scenario for copy and cut operations."""

    from plugins import pasteflow

    globals().update(
        {
            key: value
            for key, value in vars(
                importlib.import_module("pasteflow_test_support")
            ).items()
            if not key.startswith("__")
        }
    )

    def setup(big=True):
        root = tempfile.mkdtemp()
        src = os.path.join(root, "src")
        dst = os.path.join(root, "dst")
        os.makedirs(src)
        os.makedirs(dst)
        for n in ("b.bin", "a.bin"):
            with open(os.path.join(src, n), "wb") as f:
                f.write(os.urandom(40_000_000 if big else 10))
        for n in ("a0", "m1", "zz"):
            open(os.path.join(dst, n), "w").write("old")
        fm = make_fm(dst)
        d = fm.get_directory(dst)
        d.load_content(schedule=False)
        fm.thistab.thisdir = d
        fm.thistab.pathway = (d,)
        fm.thistab.path = dst
        sd = fm.get_directory(src)
        sd.load_content(schedule=False)
        return fm, d, sd, src, dst

    def ui_pump(fm, d, n=100000):
        for _ in range(n):
            d.load_content_if_outdated()  # UI draw does this every frame
            if fm.loader.has_work():
                fm.loader.work()
            else:
                time.sleep(0.01)
                d.load_content_if_outdated()
                if not fm.loader.has_work():
                    break

    for cut in (False, True):
        fm, d, sd, src, dst = setup()
        d.move_to_obj(os.path.join(dst, "zz"))  # cursor on LAST file, like real usage
        fm.copy_buffer = set(sd.files_all)
        fm.do_cut = cut
        fm.paste()
        ui_pump(fm, d)
        print(
            "cut" if cut else "copy",
            sorted(os.listdir(dst)),
            "->",
            d.files[d.pointer].basename,
            "handler",
            pasteflow._STATE.handler,
        )
        assert {"a.bin", "b.bin"}.issubset(os.listdir(dst))
        assert d.files[d.pointer].basename in {"a.bin", "b.bin"}
        assert pasteflow._STATE.handler is None


if __name__ == "__main__":
    _run_isolated_case()
