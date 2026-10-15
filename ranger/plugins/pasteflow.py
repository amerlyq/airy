"""pasteflow: the ONE wrapper around ranger's copy / cut / paste family.

WARN? `paste_symlink` jump uses a directory diff, so it assumes nobody else writes to the destination during the paste.

Other plugins (vdguard, ...) register callbacks here instead of patching Actions themselves,
so they cannot clash.  Built-in feature: after a paste the cursor jumps to the first pasted
entry (JUMP) -- for :paste, :paste_symlink, :paste_hardlink, :paste_hardlinked_subtree.

Flow of one paste (Paste object `p`):
  Actions.paste*(...)            wrapper: normalize args -> Paste(kind, dest, entries, call, opts)
    guards, in priority order    fn(p, proceed): edit p (p.drop(paths), p.after(cb)), then call
                                 proceed() -- now or later (prompt) -- or never (= cancel)
    launch                       snapshot dest listing, run the ORIGINAL method on p.entries
    finish (exactly once)        async kinds: when CopyLoader.generate ends (done / error / cancel)
                                 sync kinds (symlink, hardlink): right after the call
                                 -> p.after callbacks in registration order, jump last

API for plugins
  guard(key, fn, priority=50)    paste guard; same key replaces (re-exec safe)
  jump_to_created(fm, dest, before)   jump after a synchronous custom operation
  run_custom(fm, operation)       snapshot, run operation, then jump to created entries
  on_cut(key, fn)                fn(fm, paths) after :cut filled the buffer
  on_reset(key, fn)              fn(fm) when the buffer is replaced/emptied (:copy set, :uncut)
  unmark(fm, paths)              drop paths from the copy buffer (cancel a cut for them)
  predict_moves(paths, dest, overwrite, make_safe_path)   where ranger's mover will put them
  p.kind  "copy" | "move" | "symlink" | "hardlink" | "hardlink_tree"
  p.dest, p.entries {path: fobj}, p.call (kwargs of the original), p.opts (unknown kwargs,
  e.g. fm.paste(leave_symlink=True, jump=False)), p.landed() -> set of new basenames in dest

TROUBLESHOOT
  no jump: (a) pasted entry hidden by filter/dotfiles (not in d.files), (b) JUMP/opts jump off,
           (c) cursor dir != dest at the end, (d) signal "finished_loading_dir" never came
               (freeze_files?) -> see :display_log, logger ranger.pasteflow
  guard crashed: paste is ABORTED (never run unguarded), traceback in :display_log
  another plugin wrapped Actions.paste *args/**kw without functools.wraps: signature cannot be
  normalized -> that call passes through UNGUARDED (logged once)
EXTEND: new paste-like Action -> add its name + kind to _KINDS; jump to LAST -> reversed(d.files)
"""

from __future__ import annotations

import inspect
import logging
import os
import sys
import traceback
import types
from collections.abc import Callable
from os import path as fs

from ranger.core.actions import Actions
from ranger.core.loader import CopyLoader, Loadable
from ranger.ext.safe_path import get_safe_path

try:
    from plugins import rhooks  # ranger imports plugins as `plugins.<name>`
except ImportError:
    import rhooks  # fallback: rhooks.py somewhere on PYTHONPATH

_LOG = logging.getLogger("ranger.pasteflow")

JUMP = True  # cursor -> first pasted entry (in current sort order); per call: fm.paste(jump=False)
JUMP_KINDS = ("copy", "move", "symlink", "hardlink", "hardlink_tree")
JUMP_RETRIES = (
    3  # re-read dest this many times if the listing still lacks the pasted names
)

# Actions method -> how to name the kind; "paste" is copy or move depending on fm.do_cut
DEBUG = False  # :eval import plugins.pasteflow as p; p.DEBUG = True  -> trace in :display_log


def _trace(msg: str, *args) -> None:
    if not DEBUG:
        return
    try:
        rhooks.trace("pasteflow: " + (msg % args if args else msg))
    except Exception:
        _LOG.exception("pasteflow: persistent trace failed")


def _dbg(msg: str, *args) -> None:
    _trace(msg, *args)
    if DEBUG:
        _LOG.warning("pasteflow: " + msg, *args)


# positional order of stock ranger, used only for someone else's *a/**kw wrapper
_STOCK_ARGS = {
    "paste": ("overwrite", "append", "dest", "make_safe_path"),
    "paste_symlink": ("relative", "make_safe_path"),
}

_KINDS = {
    "paste": None,
    "paste_symlink": "symlink",
    "paste_hardlink": "hardlink",
    "paste_hardlinked_subtree": "hardlink_tree",
}

_REG = rhooks.shared("pasteflow.reg", lambda: {"guard": {}, "cut": {}, "reset": {}})
_STATE = rhooks.shared(
    "pasteflow.state", lambda: types.SimpleNamespace(current=None, handler=None)
)


def _register(kind: str, key: str, fn, priority: int) -> None:
    _REG[kind][key] = (priority, fn)


def _ordered(kind: str) -> list[Callable]:
    # stable: equal priority keeps registration order (dict order; same key keeps its slot)
    return [fn for _, fn in sorted(_REG[kind].values(), key=lambda item: item[0])]


def guard(key: str, fn, priority: int = 50) -> None:
    _register("guard", key, fn, priority)


def on_cut(key: str, fn, priority: int = 50) -> None:
    _register("cut", key, fn, priority)


def on_reset(key: str, fn, priority: int = 50) -> None:
    _register("reset", key, fn, priority)


def _call_all(kind: str, *args) -> None:
    for fn in _ordered(kind):
        try:
            _trace("hook start kind=%s fn=%r", kind, fn)
            fn(*args)
        except Exception:
            _trace("hook failed kind=%s fn=%r", kind, fn)
            _LOG.exception("pasteflow %s hook %r failed", kind, fn)


def unmark(fm, paths) -> None:
    """Cancel a cut for `paths`: they leave the buffer; nothing left -> not a cut anymore."""
    gone = set(paths)
    fm.copy_buffer = {f for f in fm.copy_buffer if f.path not in gone}
    fm.do_cut = bool(fm.copy_buffer) and fm.do_cut
    fm.ui.browser.main_column.request_redraw()


# --------------------------------------------------------------------------- #
# prediction of ranger's mover (same rule as shutil_generatorized.move/copy2)
# --------------------------------------------------------------------------- #


def _safe_like(dst: str, taken: set[str]) -> str:
    """ranger's get_safe_path(), also treating names taken earlier in the same batch as existing."""

    def exists(path: str) -> bool:
        return fs.exists(path) or path in taken

    if not exists(dst):
        return dst
    if not dst.endswith("_"):
        dst += "_"
        if not exists(dst):
            return dst
    n = 0
    while exists(dst + str(n)):
        n += 1
    return dst + str(n)


def predict_moves(
    paths, dest: str, overwrite: bool, make_safe_path=get_safe_path
) -> dict[str, str]:
    """Where ranger's mover will put each path (same rule as shutil_generatorized.move)."""
    moves: dict[str, str] = {}
    taken: set[str] = set()
    for old in paths:
        real = fs.join(dest, fs.basename(old))
        if overwrite:
            new = real
        elif make_safe_path is get_safe_path:
            new = _safe_like(real, taken)
        else:
            new = make_safe_path(real)
            if new in taken:
                _LOG.warning("cannot predict destination of %s", old)
                continue
        taken.add(new)
        moves[old] = new
    return moves


# --------------------------------------------------------------------------- #
# one paste request
# --------------------------------------------------------------------------- #


def _listing(directory: str) -> set[str]:
    try:
        return set(os.listdir(directory))
    except OSError:
        return set()


class Paste:
    def __init__(self, fm, kind, dest, entries, call, opts, orig) -> None:
        self.fm, self.kind, self.dest = fm, kind, dest
        self.call, self.opts, self.orig = call, opts, orig
        self._objs = {f.path: f for f in entries}  # everything that was in the buffer
        self.entries = dict(self._objs)  # what will be pasted (guards may drop)
        self.had_entries = bool(self.entries)
        self.before: set[str] = set()
        self.loader_seen = False
        self._after: list[Callable[[Paste], None]] = []
        self._finished = False
        self._landed: set[str] | None = None

    # -- for guards ---------------------------------------------------------- #

    @property
    def paths(self) -> list[str]:
        return list(self.entries)

    @property
    def overwrite(self) -> bool:
        return bool(self.call.get("overwrite"))

    @property
    def make_safe_path(self):
        return self.call.get("make_safe_path") or get_safe_path

    def drop(self, paths) -> None:
        for path in paths:
            self.entries.pop(path, None)

    def after(self, fn: Callable[[Paste], None]) -> None:
        """fn(p) once the files have really landed (or the paste ended early)."""
        self._after.append(fn)

    # -- results ------------------------------------------------------------ #

    def landed(self) -> set[str]:
        """Basenames that appeared in dest. Overwrite creates nothing new by name: then the
        source basenames that exist in dest count."""
        if self._landed is None:
            now = _listing(self.dest)
            new = now - self.before
            if not new:
                new = {fs.basename(path) for path in self.entries} & now
            self._landed = new
        return self._landed

    # -- run ------------------------------------------------------------------ #

    def launch(self) -> None:
        fm = self.fm
        if self.had_entries and not self.entries:
            return  # guards dropped everything: nothing left to do
        self.before = _listing(self.dest)
        _trace(
            "launch state=%#x fm=%#x orig=%s.%s kind=%s dest=%s entries=%s jump=%r",
            id(_STATE),
            id(fm),
            getattr(self.orig, "__module__", None),
            getattr(self.orig, "__qualname__", repr(self.orig)),
            self.kind,
            self.dest,
            list(self.entries)[:12],
            self.opts.get("jump", True),
        )
        _dbg(
            "launch kind=%s dest=%s entries=%d before=%d",
            self.kind,
            self.dest,
            len(self.entries),
            len(self.before),
        )
        if JUMP and self.kind in JUMP_KINDS and self.opts.get("jump", True):
            self.after(_jump)  # registered last: runs after the guards' jobs
        saved = fm.copy_buffer
        swapped = len(self.entries) != len(self._objs)
        kept = {self._objs[path] for path in self.entries}
        if swapped:  # the original reads fm.copy_buffer: hand it the reduced set
            fm.copy_buffer = kept
        kwargs = dict(self.call)
        if "dest" in kwargs:
            kwargs["dest"] = self.dest
        _STATE.current = self
        _trace("launch state.current <- paste=%#x", id(self))
        try:
            self.orig(fm, **kwargs)
        finally:
            _trace(
                "launch original returned paste=%#x loader_seen=%r",
                id(self),
                self.loader_seen,
            )
            _STATE.current = None
            if swapped:
                # ranger clears the set it was given when it moves; keep what we did not paste
                fm.copy_buffer = saved if self.kind != "move" else saved - kept
        if (
            not self.loader_seen
        ):  # sync kinds, invalid dest, empty buffer: nothing will call finish()
            self.finish()

    def finish(self) -> None:
        if self._finished:
            return
        self._finished = True
        _trace("finish paste=%#x state=%#x", id(self), id(_STATE))
        _dbg(
            "finish kind=%s loader_seen=%s after-callbacks=%d",
            self.kind,
            self.loader_seen,
            len(self._after),
        )
        for fn in self._after:
            try:
                fn(self)
            except Exception:
                _LOG.exception("pasteflow after-callback %r failed", fn)


# --------------------------------------------------------------------------- #
# jump to the first pasted entry
# --------------------------------------------------------------------------- #


def _unbind(fm) -> None:
    handler, _STATE.handler = _STATE.handler, None
    if handler is not None:
        fm.signal_unbind(handler)


def _later(fm, fn) -> None:
    """Run fn after everything queued in the loader NOW has finished. A directory load that
    emitted finished_loading_dir is still `load_generator`-pending until the loader notices
    StopIteration, so d.load_content() from inside the signal would be a silent no-op."""

    def gen():
        yield
        fn()

    fm.loader.add(Loadable(gen(), "pasteflow"), append=True)


def _jump(p: Paste) -> None:
    fm = p.fm
    new = p.landed()
    if not new:
        _dbg("jump: nothing landed in %s", p.dest)
        return
    d = fm.get_directory(p.dest)
    follow = (
        p.opts.get("jump") == "follow"
    )  # fm.paste(dest=other, jump="follow"): cd there too
    _unbind(fm)  # a newer paste supersedes a jump that is still waiting
    tries = [0]
    _dbg(
        "jump: waiting for %s to load, new=%s follow=%s",
        d.path,
        sorted(new)[:5],
        follow,
    )

    def ready(signal) -> None:
        _trace(
            "ready signal_dir=%s expected_dir=%s state.handler=%#x",
            getattr(getattr(signal, "directory", None), "path", None),
            d.path,
            id(_STATE.handler) if _STATE.handler is not None else 0,
        )
        if getattr(signal, "directory", None) is not d:
            return
        have = {f.basename for f in d.files_all or ()}
        _trace(
            "ready listing have=%s wanted=%s visible=%s",
            sorted(have)[:20],
            sorted(new)[:20],
            [f.basename for f in (d.files or ())[:20]],
        )
        if not (new & have):
            if tries[0] < JUMP_RETRIES:  # that load started before the files landed
                tries[0] += 1
                _dbg("jump: listing lacks %s, retry %d", sorted(new)[:3], tries[0])
                _later(fm, d.load_content)
                return
        _unbind(fm)
        cur = fm.thisdir
        if (cur is None or cur.path != d.path) and follow:
            fm.cd(d.path)
            cur = fm.thisdir
        if cur is None or cur.path != d.path:  # NOTE user may have cd'd away meanwhile
            _dbg(
                "jump: cursor dir %s != dest %s (no jump)",
                getattr(cur, "path", None),
                d.path,
            )
            return
        for f in d.files or ():  # d.files = visible, sorted => "first" is what you see
            if f.basename in new:
                d.move_to_obj(f.path)
                _dbg("jump: -> %s", f.basename)
                break
        else:
            _dbg(
                "jump: no visible pasted entry among %s (filtered/hidden?)",
                sorted(new)[:5],
            )

    _STATE.handler = fm.signal_bind("finished_loading_dir", ready)
    _trace(
        "jump bound handler=%#x dir=%s loading=%r generator=%r freeze=%r",
        id(_STATE.handler),
        d.path,
        d.loading,
        d.load_generator is not None,
        getattr(d.settings, "freeze_files", None),
    )
    d.load_content()  # no-op if a load is already scheduled (CopyLoader's own end-of-copy one)


def jump_to_created(fm, dest: str, before: set[str]) -> None:
    """Jump to the first visible entry created in dest since `before` was captured."""
    p = Paste(fm, "symlink", dest, (), {}, {}, lambda self: None)
    p.before = set(before)
    _jump(p)


def run_custom(fm, operation: Callable) -> None:
    """Run an operation and jump to entries it creates in the current directory."""
    dest = fm.thistab.path
    before = _listing(dest)
    operation(fm)
    jump_to_created(fm, dest, before)


## ALT: opt-in command in commands.py, no global patching.
##      benefit: only mappings that use it jump; breaks with vdsym's old async guards (queued
##      Loadable ran BEFORE the CopyLoader existed) and cannot cover :paste_symlink
# class paste_jump(Command):
#     def execute(self):
#         fm = self.fm; d = fm.thisdir
#         names = {f.basename for f in fm.copy_buffer}
#         before = {f.basename for f in (d.files_all or ())}
#         fm.paste(overwrite='overwrite' in self.args[1:])
#         def gen():
#             yield
#             d.load_content(schedule=False)
#             new = {f.basename for f in d.files_all} - before or names
#             for f in d.files:
#                 if f.basename in new:
#                     if fm.thisdir is d: d.move_to_obj(f)
#                     break
#         fm.loader.add(Loadable(gen(), 'paste_jump'), append=True)


# --------------------------------------------------------------------------- #
# guard chain
# --------------------------------------------------------------------------- #


def _run(p: Paste) -> None:
    chain = _ordered("guard")

    def step(i: int = 0) -> None:
        if i >= len(chain):
            return p.launch()
        answered: list[bool] = []

        def proceed() -> None:
            if answered:  # a prompt answered twice must not paste twice
                return
            answered.append(True)
            step(i + 1)

        try:
            chain[i](p, proceed)
        except Exception:
            _LOG.exception("pasteflow: %r failed; paste aborted", chain[i])
            p.fm.notify("paste aborted: a guard failed (:display_log)", bad=True)

    step()


# --------------------------------------------------------------------------- #
# wrappers (installed once, re-exec safe, skipped for unknown ranger shapes)
# --------------------------------------------------------------------------- #


def _make_paste_like(name: str):
    def make(orig):
        sig = inspect.signature(orig)
        params = list(sig.parameters.values())
        opaque = any(q.kind in (q.VAR_POSITIONAL, q.VAR_KEYWORD) for q in params)
        if (
            opaque
        ):  # someone else's *a/**kw wrapper (e.g. clipboard plugin loaded before us)
            _LOG.warning(
                "pasteflow: Actions.%s has an opaque signature; guessing stock argument names",
                name,
            )
        known = {q.name for q in params}

        def wrapper(self, *args, **kw):
            _trace(
                "action enter name=%s module=%s self=%#x module_obj=%#x state=%#x current=%r args=%r kwargs=%r",
                name,
                __name__,
                id(self),
                id(sys.modules[__name__]),
                id(_STATE),
                id(_STATE.current) if _STATE.current is not None else None,
                args,
                kw,
            )
            if opaque:
                # ALT:BUG: cannot tell which kwargs the other wrapper understands: only ours
                # ("jump") is taken out, the rest (leave_symlink...) is passed through AND peeked
                opts = {k: kw.pop(k) for k in ("jump",) if k in kw}
                call = dict(zip(_STOCK_ARGS.get(name, ()), args))
                call.update(kw)
                if "leave_symlink" in call:
                    opts["leave_symlink"] = call["leave_symlink"]
            else:
                opts = {k: kw.pop(k) for k in list(kw) if k not in known}
                try:
                    bound = sig.bind(self, *args, **kw)
                except TypeError:
                    return orig(self, *args, **kw)  # let ranger raise its own error
                bound.apply_defaults()
                call = dict(bound.arguments)
                call.pop(params[0].name)  # self
            kind = _KINDS[name] or ("move" if self.do_cut else "copy")
            if name == "paste":
                dest = call.get("dest") or self.thistab.path
            else:
                dest = self.thisdir.path
            _dbg(
                "%s kind=%s dest=%s n=%d call=%s opts=%s",
                name,
                kind,
                dest,
                len(self.copy_buffer),
                sorted(call),
                opts,
            )
            _run(Paste(self, kind, dest, self.copy_buffer, call, opts, orig))

        wrapper.__wrapped__ = orig
        wrapper.__doc__ = orig.__doc__
        return wrapper

    return make


def _make_copy(orig):
    def copy(self, *args, **kw):
        mode = kw.get("mode", args[0] if args else "set")
        if mode == "set":
            _call_all("reset", self)
        return orig(self, *args, **kw)

    return copy


def _make_uncut(orig):
    def uncut(self):
        _call_all("reset", self)
        return orig(self)

    return uncut


def _make_cut(orig):
    def cut(self, *args, **kw):
        orig(self, *args, **kw)  # its self.copy() fires the reset hooks
        if self.do_cut:
            _call_all("cut", self, [f.path for f in self.copy_buffer])

    return cut


def _make_loader_init(orig):
    def __init__(self, *args, **kwargs):
        p = (
            _STATE.current
        )  # the Paste whose orig() is creating this loader (sync hand-off)
        callers = " > ".join(
            f"{fs.basename(frame.filename)}:{frame.lineno}:{frame.name}"
            for frame in traceback.extract_stack(limit=12)[:-1]
        )
        if p is None:
            fm = getattr(self, "fm", None)
            entries = args[0] if args else kwargs.get("copy_buffer", ())
            dest = kwargs.get("dest") or getattr(
                getattr(fm, "thistab", None), "path", None
            )
            if fm is not None and dest:
                kind = "move" if kwargs.get("do_cut", False) else "copy"
                p = Paste(
                    fm,
                    kind,
                    dest,
                    entries,
                    {
                        key: kwargs[key]
                        for key in ("overwrite", "make_safe_path")
                        if key in kwargs
                    },
                    {},
                    lambda _fm, **_kw: None,
                )
                p.before = _listing(dest)
                if JUMP and kind in JUMP_KINDS:
                    p.after(_jump)
                p.loader_seen = True
                _trace(
                    "CopyLoader.__init__ synthesized paste=%#x kind=%s dest=%s before=%d",
                    id(p),
                    kind,
                    dest,
                    len(p.before),
                )
        self._pasteflow = p
        _trace(
            "CopyLoader.__init__ module=%s loader=%#x state=%#x current=%r copy_buffer=%r kwargs=%r callers=%s",
            __name__,
            id(self),
            id(_STATE),
            id(p) if p is not None else None,
            [
                getattr(f, "path", repr(f))
                for f in (args[0] if args else kwargs.get("copy_buffer", ()))
            ][:12],
            kwargs,
            callers,
        )
        if p is not None:
            p.loader_seen = True
        orig(self, *args, **kwargs)

    return __init__


def _make_loader_generate(orig):
    def generate(self):
        p = getattr(self, "_pasteflow", None)
        _trace(
            "CopyLoader.generate enter module=%s loader=%#x state=%#x paste=%r",
            __name__,
            id(self),
            id(_STATE),
            id(p) if p is not None else None,
        )
        try:
            yield from orig(self)
        finally:  # completion, error or cancel: reconcile what really landed
            _trace(
                "CopyLoader.generate finally loader=%#x paste=%r",
                id(self),
                id(p) if p is not None else None,
            )
            if p is not None:
                p.finish()

    return generate


def _install() -> None:
    _trace(
        "install begin module=%s file=%s module_obj=%#x rhooks=%s rhooks_obj=%#x "
        "Actions=%s.%s CopyLoader=%s.%s state=%#x",
        __name__,
        __file__,
        id(sys.modules[__name__]),
        getattr(rhooks, "__file__", None),
        id(rhooks),
        Actions.__module__,
        Actions.__name__,
        CopyLoader.__module__,
        CopyLoader.__name__,
        id(_STATE),
    )
    try:
        for name in _KINDS:
            if hasattr(Actions, name):
                rhooks.patch(Actions, name, _make_paste_like(name))
        rhooks.patch(Actions, "copy", _make_copy)
        rhooks.patch(Actions, "uncut", _make_uncut)
        rhooks.patch(Actions, "cut", _make_cut)
        rhooks.patch(CopyLoader, "__init__", _make_loader_init)
        rhooks.patch(CopyLoader, "generate", _make_loader_generate)
    except Exception:
        _trace("install exception module=%s", __name__)
        _LOG.exception("pasteflow: wrappers not installed")


# rnvimr loads plugin files as bare modules, while Ranger loads them as
# `plugins.<name>`. Keep both import names attached to this one module instance.
_module = sys.modules[__name__]
if __name__ == "pasteflow":
    sys.modules.setdefault("plugins.pasteflow", _module)
elif __name__ == "plugins.pasteflow":
    sys.modules.setdefault("pasteflow", _module)
_trace(
    "module ready name=%s file=%s module_obj=%#x aliases=(%r,%r) rhooks=%s rhooks_obj=%#x state=%#x",
    __name__,
    __file__,
    id(_module),
    sys.modules.get("pasteflow") is _module,
    sys.modules.get("plugins.pasteflow") is _module,
    getattr(rhooks, "__file__", None),
    id(rhooks),
    id(_STATE),
)


_install()
