"""Briefly fade changed entries in the browser listing.

OPTIONS: MODE = "pasted" (any|pasted|none), STYLE = "steps" (steps|blink),
         COLORS = "override" (override|blend|reverse).
ALG: pending paths are stored per directory; the draw hook tints each matching row's
background so multi-file pastes and selected rows use the same flash.
"""

from __future__ import annotations

import curses
import os
import time
import types

from ranger.gui import color as ranger_color
from ranger.gui import colorscheme as ranger_colorscheme
from ranger.gui import ui as ranger_ui
from ranger.gui.widgets import browsercolumn

try:
    from plugins import pasteflow, rhooks
except ImportError:
    import pasteflow
    import rhooks


MODE = "any"  # VIZ=<any|pasted|none>
STYLE = "steps"  # VIZ=<steps|blink>
COLORS = "override"  # VIZ=<override|blend|reverse>
DURATION = 0.4  # all fade steps complete in under one second
# PALETTE = (226, 220, 214, 208)
PALETTE = (226, 214, 208, 130)  # xterm-256 yellow-orange ramp, bright to dark
STEPS = len(PALETTE)
_BLENDED = {}
_STATE = rhooks.shared(
    "flash_changes.state",
    lambda: types.SimpleNamespace(
        fm=None, flashes={}, pending={}, snapshots={}, stages={}
    ),
)
_CONTEXTS = tuple("flash_step_%d" % i for i in range(STEPS))


def _stage(path: str, now: float) -> int | None:
    until = _STATE.flashes.get(path)
    if until is None:
        return None
    remaining = until - now
    if remaining <= 0:
        _STATE.flashes.pop(path, None)
        return None
    if STYLE == "blink":
        return 0
    elapsed = DURATION - remaining
    return min(STEPS - 1, int(elapsed * STEPS / DURATION))


def _draw_hook(orig):
    def hook(fsobject, color_list):
        fsobject, color_list = orig(fsobject, color_list)
        stage = _stage(fsobject.path, time.monotonic())
        if stage is not None:
            color_list = list(color_list) + [_CONTEXTS[stage]]
        return fsobject, color_list

    return hook


def _blend_color(orig):
    def get(self, *keys):
        step = next((i for i, key in enumerate(_CONTEXTS) if key in keys), None)
        if step is None:
            return orig(self, *keys)
        base = orig(self, *(key for key in keys if key not in _CONTEXTS))
        fg, bg, attr = base
        if COLORS == "reverse":
            return fg, bg, attr | curses.A_REVERSE
        if COLORS == "override":
            return fg, PALETTE[step], attr
        base_bg = ranger_color.DEFAULT_BACKGROUND if bg < 0 else bg
        cache_key = (base_bg, step)
        blended_bg = _BLENDED.get(cache_key)
        if blended_bg is None:
            try:
                base_rgb = curses.color_content(base_bg)
                flash_rgb = curses.color_content(PALETTE[0])
                weight = (STEPS - step) / (STEPS + 1)
                target = tuple(
                    round(base_rgb[i] * (1 - weight) + flash_rgb[i] * weight)
                    for i in range(3)
                )
                blended_bg = min(
                    range(max(1, getattr(curses, "COLORS", 0))),
                    key=lambda color: sum(
                        (curses.color_content(color)[i] - target[i]) ** 2
                        for i in range(3)
                    ),
                )
            except curses.error, ValueError:
                blended_bg = base_bg
            _BLENDED[cache_key] = blended_bg
        return fg, blended_bg, attr

    return get


def _signature(directory: str) -> dict[str, tuple[int, int, int]]:
    try:
        with os.scandir(directory) as entries:
            result = {}
            for entry in entries:
                try:
                    stat = entry.stat(follow_symlinks=False)
                except OSError:
                    continue
                result[entry.name] = (stat.st_mtime_ns, stat.st_size, stat.st_ino)
            return result
    except OSError:
        return {}


def _queue(directory: str, names) -> None:
    if names:
        _STATE.pending.setdefault(directory, set()).update(names)


def _refresh(paths) -> None:
    fm = _STATE.fm or rhooks.fm()
    if fm is None:
        return
    _STATE.fm = fm
    paths = set(paths)
    if not paths:
        return
    directories = {os.path.dirname(path) for path in paths}
    for path in paths:
        directory = fm.get_directory(os.path.dirname(path))
        for entry in directory.files_all or ():
            if entry.path == path:
                entry.display_data.clear()
                break
    for column in getattr(fm.ui.browser, "columns", ()) or ():
        if getattr(getattr(column, "target", None), "path", None) in directories:
            column.request_redraw()
    redraw = getattr(fm.ui, "redraw", None)
    if callable(redraw) and getattr(fm.ui, "is_on", True):
        redraw()


def _set_animation_timeout(active: bool) -> None:
    fm = _STATE.fm or rhooks.fm()
    if fm is None or not getattr(fm.ui, "is_on", False) or fm.ui.load_mode:
        return
    previous = getattr(_STATE, "fast_poll", False)
    if active == previous:
        return
    try:
        # Ranger otherwise blocks in getch() longer than this entire fade.
        ticks = 1 if active else max(1, min(255, fm.settings.idle_delay // 100))
        curses.halfdelay(ticks)
    except curses.error:
        return
    _STATE.fast_poll = active


def _make_load_mode(orig):
    def set_load_mode(ui, boolean):
        result = orig(ui, boolean)
        if not boolean and _STATE.flashes:
            try:
                # Ranger reapplies idle_delay after loader work; keep animation polling faster.
                curses.halfdelay(1)
            except curses.error:
                pass
        return result

    return set_load_mode


def _start(directory: str, names) -> None:
    now = time.monotonic()
    paths = set()
    for name in names:
        path = os.path.join(directory, name)
        _STATE.flashes[path] = now + DURATION
        _STATE.stages.pop(path, None)
        paths.add(path)
    _STATE.pending.pop(directory, None)
    _refresh(paths)


def _scan() -> None:
    if MODE != "any":
        return
    fm = _STATE.fm or rhooks.fm()
    if fm is None:
        return
    _STATE.fm = fm
    paths = {tab.path for tab in fm.tabs.values() if getattr(tab, "path", None)}
    paths.update(_STATE.snapshots)
    for directory in paths:
        current = _signature(directory)
        previous = _STATE.snapshots.get(directory)
        if previous is not None:
            changed = {
                name
                for name, signature in current.items()
                if previous.get(name) != signature
            }
            _queue(directory, changed)
            if directory == fm.thistab.path and changed:
                _start(directory, changed)
        _STATE.snapshots[directory] = current
    for tab in fm.tabs.values():
        directory = getattr(tab, "path", None)
        if directory == fm.thistab.path and directory in _STATE.pending:
            _start(directory, _STATE.pending[directory])


def _tick() -> None:
    fm = _STATE.fm or rhooks.fm()
    if fm is not None:
        _STATE.fm = fm
    if MODE == "any":
        _scan()
    if fm is not None and fm.thistab.path in _STATE.pending:
        _start(fm.thistab.path, _STATE.pending[fm.thistab.path])
    now = time.monotonic()
    dirty = set()
    for path in list(_STATE.flashes):
        stage = _stage(path, now)
        if stage is None:
            _STATE.stages.pop(path, None)
            dirty.add(path)
        elif _STATE.stages.get(path) != stage:
            _STATE.stages[path] = stage
            dirty.add(path)
    if dirty:
        _refresh(dirty)
    _set_animation_timeout(bool(_STATE.flashes))


def _pasted(paste) -> None:
    if MODE == "pasted":
        _queue(paste.dest, paste.landed())
        fm = paste.fm
        _STATE.fm = fm
        if getattr(getattr(fm, "thisdir", None), "path", None) == paste.dest:
            _start(paste.dest, _STATE.pending.get(paste.dest, ()))


def _guard(paste, proceed) -> None:
    paste.after(_pasted)
    proceed()


rhooks.patch(browsercolumn, "hook_before_drawing", _draw_hook)
rhooks.patch(ranger_colorscheme.ColorScheme, "get", _blend_color)
rhooks.patch(ranger_ui.UI, "set_load_mode", _make_load_mode)
pasteflow.guard("flash_changes", _guard, 1000)
rhooks.on_tick("flash_changes", _tick)
