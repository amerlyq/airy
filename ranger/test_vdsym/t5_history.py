# history_navi: <cl> <H> <cl> must not grow history, fork policy, wrapper-order independence.
import os
import sys

import history_navi as H
import ranger
from ranger.container.history import History

import paths  # noqa: F401  (plugin dir on sys.path, isolated state)


class D:  # Directory stand-in: one object per path, like fm.get_directory()
    _c = {}

    def __new__(cls, p):
        return cls._c.setdefault(p, super().__new__(cls))

    def __init__(s, p):
        s.path = p

    def __repr__(s):
        return s.path


def mk(n):
    h = History(2000, unique=False)
    for i in range(n):
        h.history.append(D(f"/d{i}"))
    h.index = n - 1
    return h


def jump(h, old, new):  # what enter_dir() records for a non-step jump
    H._visit(h, D(old))
    H._visit(h, D(new))


def state(h):
    return f"[{h.index + 1}/{len(h)}]"


# --- <cl> <H> <cl> <H> ... never grows (it grew by 2 per cycle before)
h = mk(3)
jump(h, "/d2", "/x")
sizes = []
for _ in range(5):
    h.move(-1)  # <H>
    assert h.current().path == "/d2"
    jump(h, "/d2", "/x")
    sizes.append(len(h))
assert sizes == [4] * 5 and h.index == 3, sizes

# --- [1/35] + jump: truncate => [2/2], insert => [2/36]
h = mk(35)
h.move(-34)
assert state(h) == "[1/35]"
jump(h, "/d0", "/y")
assert state(h) == "[2/2]", state(h)
saved, H.FORK = H.FORK, "insert"
h = mk(35)
h.move(-34)
jump(h, "/d0", "/y")
assert state(h) == "[2/36]" and h.history[2].path == "/d1", state(h)
H.FORK = saved

# --- chain A -> D -> S1 -> S2 -> A, walked back and forward again
h = History(2000, unique=False)
h.history.append(D("/A"))
h.index = 0
for a, b in [("/A", "/D"), ("/D", "/S1"), ("/S1", "/S2"), ("/S2", "/A")]:
    jump(h, a, b)
assert state(h) == "[5/5]"
assert [h.move(-1).path for _ in range(4)] == ["/S2", "/S1", "/D", "/A"]
for a, b in [("/A", "/D"), ("/D", "/S1")]:
    jump(h, a, b)  # retrace: no growth
assert len(h) == 5 and h.current().path == "/S1"

# --- maxlen
h = History(3, unique=False)
h.history.append(D("/a"))
h.index = 0
for a, b in [("/a", "/b"), ("/b", "/c"), ("/c", "/d")]:
    jump(h, a, b)
assert len(h) == 3 and h.current().path == "/d"

# --- console history keeps ranger's own History.add
assert History.add.__module__ == "ranger.container.history"

# --- _is_step: first frame inside the ranger package decides; foreign wrappers are skipped
RANGER_DIR = os.path.dirname(os.path.abspath(ranger.__file__))
ns = {}
exec(
    compile(
        "def move(call):\n    return call()\n"
        "def move_parent(call, n=1):\n    return call()\n"
        "def cd(call):\n    return call()\n",
        RANGER_DIR + "/core/actions.py",
        "exec",
    ),
    ns,
)
pns = {}
exec(
    compile(
        "def wrapper(call):\n    return call()\n",
        "/home/u/.config/ranger/plugins/other.py",
        "exec",
    ),
    pns,
)


def chain(name, wrapped, **kw):
    inner = lambda: (lambda: H._is_step(sys._getframe(1)))()  # noqa: E731
    call = (lambda: pns["wrapper"](inner)) if wrapped else inner
    return ns[name](call, **kw)


assert chain("move", False) is True
assert chain("move", True) is True  # a foreign wrapper in between: still a step
assert (
    chain("move_parent", True, n=1) is True and chain("move_parent", True, n=2) is False
)
assert chain("cd", True) is False  # another ranger caller: a real jump
assert H._is_step(sys._getframe(0)) is False  # no ranger frame within reach
print("OK5")
