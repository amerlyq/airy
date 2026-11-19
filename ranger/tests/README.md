# Plugin tests

The suite targets Python 3.14 and uses pytest. From the repository root:

```sh
python3.14 -m pytest
```

Integration tests are regular pytest tests and are included in the default run.
Tests that patch Ranger hooks run their pytest module in a child process so the
patches cannot leak into other tests. The child process is launched by the
pytest fixture; no scenario scripts need to be run separately.

Filesystem benchmarks use the `benchmark` marker and are excluded by default.
Select them with pytest's standard marker filter:

```sh
python3.14 -m pytest -m benchmark -s
```

Run benchmark and regular tests together with:

```sh
python3.14 -m pytest -m "not benchmark or benchmark"
```

To select the marked integrations explicitly, use `-m integration`. To select
slow tests, use `-m slow`. Tests create temporary files and use this checkout's
`plugins/`; `fd` is optional and no graphical session is needed.
