"""Import this first: makes `import vdsym` / `import history_navi` find the plugins and keeps
every test away from your real ranger state.

Plugin dir: $VDSYM_PLUGINS, else ../plugins relative to this directory (~/.config/ranger/plugins
when the tests live in ~/.config/ranger/test).
"""

import atexit
import os
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PLUGINS = os.environ.get("VDSYM_PLUGINS") or os.path.join(
    os.path.dirname(HERE), "plugins"
)
if not os.path.isfile(os.path.join(PLUGINS, "vdsym.py")):
    sys.exit(f"vdsym.py not found in {PLUGINS} (set VDSYM_PLUGINS)")
sys.path[:0] = [HERE, PLUGINS]

# moves.log / recovery files go to a throw-away XDG_STATE_HOME, never to ~/.local/state
if not os.environ.get("VDSYM_TEST_REAL_STATE"):
    _state = tempfile.mkdtemp(prefix="vdsym-state-")
    os.environ["XDG_STATE_HOME"] = _state
    atexit.register(shutil.rmtree, _state, ignore_errors=True)
