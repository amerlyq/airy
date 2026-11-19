"""Pytest coverage for plugin behavior that requires a fresh Ranger process."""

from pathlib import Path
import importlib

import pytest


@pytest.mark.integration
def test_vdguard_cut(run_isolated_test_module):
    result = run_isolated_test_module(Path(__file__))
    assert result.returncode == 0, result.stdout


def _run_isolated_case():
    """Process-isolated vdguard cut and paste integration scenario."""

    import sys
    from pathlib import Path

    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import importlib

    globals().update(
        {
            key: value
            for key, value in vars(
                importlib.import_module("pasteflow_test_support")
            ).items()
            if not key.startswith("__")
        }
    )

    root = tempfile.mkdtemp()
    data = os.path.join(root, "data")
    view = os.path.join(root, "view")
    view2 = os.path.join(root, "view2")
    for d in (data, view, view2):
        os.makedirs(d)
    fm = make_fm(view)
    fm.execute_command = lambda *a, **k: None
    mods = {
        n: importlib.import_module("plugins." + n)
        for n in sorted(
            [
                "pasteflow",
                "rhooks",
                "vdconf",
                "vddangling",
                "vdguard",
                "vdsym",
                "vdutil",
            ]
        )
    }
    vd, guard, C = mods["vdsym"], mods["vdguard"], mods["vdconf"]
    vd.vdsym.data_roots = (data,)
    vd.vdsym.view_root = view
    C.DASHBOARD_ROOT = os.path.join(root, "dash")
    C.RECOVERY_LOG = os.path.join(root, "rec.log")
    C.WARM_ON_CD = False
    con = fm.ui.console

    def mk(p):
        os.makedirs(os.path.dirname(p), exist_ok=True)
        open(p, "w").write("x")
        return p

    def goto(d):
        dd = fm.get_directory(d)
        dd.load_content(schedule=False)
        fm.thistab.thisdir = dd
        fm.thistab.pathway = (dd,)
        fm.thistab.path = d
        return dd

    f = mk(os.path.join(data, "a.mp4"))
    os.symlink(f, os.path.join(view, "a.mp4"))  # the link we move
    os.symlink(
        os.path.join(view, "a.mp4"), os.path.join(view, "chain.mp4")
    )  # link pointing AT the link
    d = goto(view)
    d.move_to_obj(os.path.join(view, "a.mp4"))
    con.answers[:] = ["U"]
    fm.cut()
    print("asks after dd:", len(con.asked), con.asked)
    assert not con.asked  # dependency scan is asynchronous at cut time
    goto(view2)
    con.answers[:] = ["U"]
    fm.paste()
    pump(fm)
    print("asks total after pp:", len(con.asked))
    print(con.asked[-1][:160])
    assert len(con.asked) == 1
    assert con.asked[0].startswith("symlink chain.mp4")
    assert os.path.exists(os.path.join(view2, "a.mp4"))


if __name__ == "__main__":
    _run_isolated_case()
