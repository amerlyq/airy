"""Pytest coverage for plugin behavior that requires a fresh Ranger process."""

from pathlib import Path

import pytest


@pytest.mark.benchmark
@pytest.mark.slow
def test_vdsym_benchmark_links50k(run_isolated_test_module):
    result = run_isolated_test_module(Path(__file__))
    assert result.returncode == 0, result.stdout


def _run_isolated_case():
    """Opt-in dangling-link benchmark for vdsym and vddangling."""

    # Benchmark: cost of check_dangling() with 50k symlinks (runs on every refreshing :vdsym).
    import os
    import shutil
    import sys
    import tempfile
    import time
    import types
    from os import path as fs

    from plugins import vdsym as M
    from plugins import vddangling as D

    import plugin_test_paths as paths  # noqa: F401

    base = tempfile.mkdtemp(prefix="vdp3")
    view, d1 = fs.join(base, "view"), fs.join(base, "vd")
    M.vdsym.view_root = view
    M.vdsym.data_roots = (d1,)
    os.makedirs(view)
    os.makedirs(d1)
    for i in range(50000):
        os.symlink(
            fs.join(d1, f"f{i}.mp4") if i % 100 else "/gone", fs.join(view, f"l{i}")
        )
    for i in range(0, 50000, 2):
        open(fs.join(d1, f"f{i}.mp4"), "w").close()
    roots = M.vdsym.roots()
    M._cache.ensure(roots)
    time.sleep(2.2)
    M._cache.ensure(roots, "validate")
    # The dangling monitor tracks dangling targets only (500 here), while the
    # cache index tracks all 50,000 link entries.
    assert D._mon.known is None
    t = time.perf_counter()
    r = D.check_dangling(None)
    assert r == []  # first check establishes baseline
    # Half the names have backing files, except each hundredth is deliberately
    # pointed at /gone: 25,000 odd missing targets + 500 forced dangling links.
    assert len(D._mon.known) == 25_500
    print(
        "baseline check, 50k links:",
        round(time.perf_counter() - t, 3),
        len(D._mon.known),
    )
    t = time.perf_counter()
    r = D.check_dangling(None)
    print("repeat check, 50k links  :", round(time.perf_counter() - t, 3), r)
    assert r == []
    shutil.rmtree(base)


if __name__ == "__main__":
    _run_isolated_case()
