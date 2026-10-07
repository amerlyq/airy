# vdsym / history_navi tests

Put this directory at `~/.config/ranger/test/` (plugins in `~/.config/ranger/plugins/`:
`vdsym.py`, `history_navi.py`). Otherwise set `VDSYM_PLUGINS=/dir/with/the/plugins`.

    ./run_tests.py             # all t*.py, each in its own process
    ./run_tests.py --bench     # + bench_*.py (prints timings)
    ./run_tests.py t3 t4       # only some files
    python3 t4_reliability_dangling.py   # a single file works too

Requirements: the `ranger` package importable (the tests drive the real `Actions`, `CopyLoader`,
`Loader`, stock `delete`/`rename`, `History` with a fake file manager); `fd` optional.

Isolation: `paths.py` points `XDG_STATE_HOME` at a temp dir (your real `moves.log` is never
touched; `VDSYM_TEST_REAL_STATE=1` disables that) and all trees live under `$TMPDIR`.
Nothing is ever created in your real VD roots; the roots are monkey-patched to temp dirs.

| file | covers |
|---|---|
| `harness.py` | fake fm (Actions subclass), console that answers like ranger (Enter=choices[0], Esc=choices[1]) |
| `t1_search_replace.py` | search modes, print, replace, dashboards, backlinks, clips, delete, cache persistence |
| `t2_delete_refresh.py` | delete prompts, refresh modes, `cv`/`cV` details, cd signal |
| `t3_moves.py` | cut/paste/rename guards, U/R, recovery log, pics layout, racy mtimes, hooks |
| `t4_reliability_dangling.py` | R semantics, inode relocation, existence filter, unreadable dirs, dangling check + timer, `:dangling` |
| `t5_history.py` | history_navi (no growth on `<cl><H><cl>`, FORK policy, `_is_step`) |
| `bench_80k.py`, `bench_links50k.py` | timings (not asserted) |

Conventions: a test file is a plain script, `assert`s on failure, prints `OKn` at the end.
When a feature changes on purpose, update the assertion that documents the old behaviour
(for example the collision case of R used to expect an untouched old link).
Tests set `DANGLING_MONITOR = False` where their fixtures leave dangling links on purpose.
