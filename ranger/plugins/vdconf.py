"""vdconf: every setting of the VD plugins in one place (vdsym, vddangling, vdguard).

Plugins read `C.NAME` at call time, so `:eval` / a reload of this file changes behavior without
restarting (except default-argument values, which are bound at import).
Roots (data_roots / view_root) stay class attributes of :vdsym, they are code-adjacent.
"""

from __future__ import annotations

import os

DASHBOARD_ROOT = "/t/bnm"


# Cache freshness before a :vdsym search.
#
# "validate" stat-walks every cached directory.
# It rescans only directories whose mtime changed.
# This catches changes made outside ranger.
# It is reliable when directory mtimes are reliable.
# It costs one stat per cached directory.
# It is the default.
#
# "visited" remembers each VD directory reached by ranger's cd signal.
# It remembers both the displayed spelling and realpath spelling.
# The next visited-mode search rescans each remembered directory subtree.
# Dashboard creation also remembers source directories plus symlink target directories.
# This cheaply catches work done during this ranger session.
# It can miss external changes in unvisited directories.
# It can miss a symlinked directory when ranger keeps an outside symlink-leaf spelling.
#
# "none" trusts the index except that gone matched paths are filtered out.
# "rescan" rebuilds every root from scratch.
#
# --modifiers=norefresh forces "none".
# --action=refresh forces "validate".
# --action=rescan forces "rescan".
REFRESH = "validate"
# Clip naming: "<stem>_00m33s6", "<stem>_v32", "<stem>_06m44s7_prev29267", any extension.
_TOKEN = r"(?:\d+m\d+s\d+|v\d+|prev\d+)"
CLIP_SUFFIX = _TOKEN + "(?:_" + _TOKEN + ")*"


WARM_ON_CD = True  # start the background cache build on the first cd() under a VD root
DELETE_SCANS_DIRS = True  # :delete also looks for links into directories being deleted


# Pictures live in "<dnum>" or "<dnum>-*" dirs directly under a parent named like one of these
# (the first "*" is the date prefix). Those dirs are never listed; for a needle "<dnum>-<idx>"
# the files "<dnum>-<idx>.<ext>" with 0..PICS_ZEROES zeroes before <idx> are probed instead.
PICS_PARENTS = ("*-*-pics", "*-*-pics-*")
PICS_EXTS = ("mp4", "webp", "gif")
PICS_ZEROES = 3


LOCK_WAIT = (
    3.0  # s a guard waits for the cache lock (warm-up running) before asking blind
)


PRINT_BEFORE_PROMPT = (
    True  # page the symlink list before a move prompt (recovery on cancel/crash)
)


# "any" accepts the next key.
# Any other string accepts only its characters.
# Use "\n yqc" for Enter, space, y, q or c.
PRINT_DISMISS_KEYS = "any"


# Print-match emphasis is bold yellow.
# "rest" emphasizes matching basenames except for the search term.
# "needle" emphasizes the search term instead.
PRINT_HIGHLIGHT = "rest"


RECOVERY_LOG = os.path.join(
    os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state"),
    "vdsym",
    "moves.log",
)


RACY_NS = 2_000_000_000  # dirs modified < 2s before their scan are re-read next time


# Dangling symlinks: bulkrename, shell mv / rm and other tools can't be hooked, so they are
# caught afterwards. Every :vdsym that refreshes compares the links that dangle now with the
# previous check and, before doing its job, tells you about new ones. If you then stop using
# vdsym, a ranger timer repeats the comparison once after DANGLING_QUIET s without VD activity.
DANGLING_MONITOR = True
DANGLING_QUIET = 30.0
