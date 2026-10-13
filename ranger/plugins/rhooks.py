"""rhooks: tiny kit shared by my ranger plugins (patching, cd signal, idle tick).

Why a kit: every plugin that wrapped ranger internals re-invented the same three things
(idempotent monkey-patch, a cd-signal binding, a timer) and the wrappers clashed.
Now: ONE wrapper per ranger method (pasteflow owns Actions.paste*), plugins register callbacks.

  shared(key, factory)   process-wide state that survives a module re-exec (plugin reload)
  patch(owner, name, make)   idempotent wrap: make(original) -> wrapper; never wraps twice
  on_cd(key, fn)         fn(path) on every cd (a SIGNAL, not a Tab.enter_dir wrapper:
                         history_navi inspects the caller frame of enter_dir and must stay outermost)
  on_tick(key, fn)       fn() whenever ranger's loader runs (>= every ~2 s while idle)
  fm()                   the FM instance once known (None before)

Registering again under the same key REPLACES the callback (re-exec safe, no duplicates).
"""

from __future__ import annotations

import logging
import sys
import types

_LOG = logging.getLogger("ranger.rhooks")


def shared(key: str, factory):
    """Get-or-create process-wide state; lives in sys.modules so a re-exec of the plugin keeps it."""
    holder = sys.modules.setdefault(
        "_rhooks_shared", types.ModuleType("_rhooks_shared")
    )
    state = holder.__dict__.setdefault("state", {})
    if key not in state:
        state[key] = factory()
    return state[key]


def patch(owner, name: str, make) -> None:
    """owner.name = make(original). `original` is always the UNPATCHED method, also after a
    re-exec (it is remembered in shared state), so wrappers never stack on themselves.
    ALT:BUG: a wrapper from a *different* plugin installed before us is taken as 'original'."""
    originals = shared("orig", dict)
    original = originals.setdefault((owner, name), getattr(owner, name))
    setattr(owner, name, make(original))


# --------------------------------------------------------------------------- #
# cd signal
# --------------------------------------------------------------------------- #

_S = shared(
    "rhooks", lambda: types.SimpleNamespace(cd={}, tick={}, fm=None, init=False)
)


def fm():
    return _S.fm


def _dispatch_cd(signal) -> None:
    new = getattr(signal, "new", None)
    if new is None:
        return
    for key, fn in list(_S.cd.items()):
        try:
            fn(new.path)
        except Exception:
            _LOG.exception("rhooks: cd handler %s failed", key)


def _bind(fm_) -> None:
    if fm_ is None or getattr(fm_, "_rhooks_cd", False):
        return
    fm_._rhooks_cd = True
    _S.fm = fm_
    fm_.signal_bind("cd", _dispatch_cd)


def on_cd(key: str, fn) -> None:
    _S.cd[key] = fn
    try:
        import ranger
        import ranger.api

        _bind(getattr(ranger, "fm", None))
        if (
            not _S.init
        ):  # fm may not exist yet while plugins load: bind from hook_init too
            _S.init = True
            previous = ranger.api.hook_init

            def hook_init(fm_):
                _bind(fm_)
                return previous(fm_)

            ranger.api.hook_init = hook_init
    except Exception:
        _LOG.exception("rhooks: cd signal not installed")


# --------------------------------------------------------------------------- #
# idle tick (ranger's main loop calls Loader.work() at least every idle_delay, 2 s)
# --------------------------------------------------------------------------- #


def _make_work(orig):
    def work(self, *args, **kwargs):
        result = orig(self, *args, **kwargs)
        for key, fn in list(_S.tick.items()):
            try:
                fn()
            except Exception:
                _LOG.exception("rhooks: tick handler %s failed", key)
        return result

    return work


def on_tick(key: str, fn) -> None:
    _S.tick[key] = fn
    try:
        from ranger.core.loader import Loader

        patch(Loader, "work", _make_work)
    except Exception:
        _LOG.exception("rhooks: tick not installed")
