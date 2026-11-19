"""Import this first: adds the test and repository roots for `plugins.*` imports and keeps
every test away from your real ranger state.

Plugin source: the repository `plugins/` package.
"""

import atexit
import os
import shutil
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
PLUGINS = os.path.join(os.path.dirname(HERE), "plugins")
if not os.path.isfile(os.path.join(PLUGINS, "vdsym.py")):
    sys.exit(f"plugins/vdsym.py not found in {PLUGINS}")
sys.path[:0] = [HERE, os.path.dirname(HERE)]

# moves.log / recovery files go to a throw-away XDG_STATE_HOME, never to ~/.local/state
if not os.environ.get("VDSYM_TEST_REAL_STATE"):
    _state = tempfile.mkdtemp(prefix="vdsym-state-")
    os.environ["XDG_STATE_HOME"] = _state
    atexit.register(shutil.rmtree, _state, ignore_errors=True)
