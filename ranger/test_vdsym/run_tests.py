#!/usr/bin/env python3
"""Run the vdsym / history_navi test-suite (and optionally the benchmarks).

    ./run_tests.py            tests only
    ./run_tests.py --bench    tests, then benchmarks
    ./run_tests.py t3 t4      only files whose name starts with t3 / t4
    VDSYM_PLUGINS=/path/to/plugins ./run_tests.py

Every file runs in its own process: they patch ranger classes (Actions, Loader, Tab) and
build their own fake file manager, so they must not share an interpreter.
Needs the `ranger` package importable; `fd` is optional (without it the scandir path is used).
"""

import glob
import os
import shutil
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
args = [a for a in sys.argv[1:] if not a.startswith("--")]
bench = "--bench" in sys.argv

tests = sorted(glob.glob(os.path.join(HERE, "t[0-9]*.py")))
benches = sorted(glob.glob(os.path.join(HERE, "bench_*.py"))) if bench else []
if args:
    tests = [t for t in tests if any(os.path.basename(t).startswith(a) for a in args)]
    benches = [
        b for b in benches if any(os.path.basename(b).startswith(a) for a in args)
    ]

scratch = tempfile.mkdtemp(prefix="vdsym-tests-")
env = dict(os.environ, TMPDIR=scratch, PYTHONDONTWRITEBYTECODE="1")
failed = []
try:
    for kind, files in (("test", tests), ("bench", benches)):
        for path in files:
            name = os.path.basename(path)
            started = time.time()
            run = subprocess.run(
                [sys.executable, path],
                env=env,
                cwd=HERE,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            )
            took = time.time() - started
            if run.returncode == 0:
                print(f"ok    {name:34s} {took:6.1f}s")
                if kind == "bench":
                    print(
                        "".join("      " + line for line in run.stdout.splitlines(True))
                    )
            else:
                failed.append(name)
                print(f"FAIL  {name:34s} {took:6.1f}s")
                print(
                    "".join(
                        "      " + line for line in run.stdout.splitlines(True)[-25:]
                    )
                )
finally:
    shutil.rmtree(scratch, ignore_errors=True)
print(f"\n{len(tests) + len(benches) - len(failed)} passed, {len(failed)} failed")
sys.exit(1 if failed else 0)
