Tests require ranger's Python package.
This repository contains ranger configuration rather than ranger itself.
Use an existing ranger source checkout without installing it:

```sh
cd /tmp/airy-ranger-sync-upstream
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s /d/airy/ranger/tests -v
```

Equivalent command from `/d/airy`:

```sh
PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=/tmp/airy-ranger-sync-upstream python3 -m unittest discover -s ranger/tests -v
```

If that checkout is absent:

```sh
git clone --depth 1 https://github.com/ranger/ranger.git /tmp/airy-ranger-sync-upstream
```

Tests use ranger's actual signal dispatcher, keymaps, command registry and
`select_file` implementation.
Directory movement is simulated without curses.
Transport tests use a real UNIX socket plus shell expansion.
No running imv or graphical session is required.

Status queries run on one background worker per controller.
Only the ranger thread may apply a result.
Keyboard input invalidates earlier queries even when the cursor cannot move.
Mouse input also invalidates earlier queries.
Results must still match the socket, tab, directory and input generation.
Queued input is processed before completed query results.
Forward IPC sends still run synchronously.

Manual GUI check after restarting ranger:

1. Open an image through rifle.
2. Navigate rapidly in imv; ranger should follow without changing imv's selection.
3. Navigate using ranger keys or mouse; imv should follow the final selection.
   Switch from imv and immediately press Down; later polls must not undo it.
   Repeat with parent-folder navigation; ranger must stay in the parent.
4. Change ranger sorting/filtering; the next image move should rebuild imv's list.
5. Press `M`; original `i`/`m`/`M` mappings should return.
6. Open another imv; tracking should resume.

Socket discovery preserves the existing newest-instance policy.
It does not prove which process launched imv.
An unrelated imv launched after ranger startup can also be discovered.

IPC behavior was checked against imv 5.0.1 sources (`src/ipc.c`, `src/imv.c`).
Commands are capped at 1023 bytes because imv treats each socket receive as one command.
The client half-closes its write side before waiting for server EOF.
That establishes enqueue order across connections; it is not an execution reply.
An `exec printf` snapshot reads the selection after preceding commands execute.
