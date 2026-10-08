"""treefilter: tree-preserving recursive search filter for ranger (>= 1.9).

    :tfilter_fd [fd flags] [PATTERN]     match names     (runs `fd`)
    :tfilter_rg [rg flags] PATTERN       match contents  (runs `rg`)
    :tfilter_undo [-a]

Flags are forwarded to fd/rg unchanged, except ones that would break parsing
of the result (-x/-l/--json/...; rejected with a message). Don't pass search
paths: the scope is chosen for you:

  * marked files/dirs, if any, else what the current dir shows right now
    (hidden/:filter/filter_stack/earlier treefilters all apply)
  * passed to fd/rg as paths when that is possible, else whole cwd + post-filter

Result: the tree shows only matches and the dirs leading to them, at every
depth. Searches run asynchronously through ranger's loader (^C / :abort stops).
Treefilters nest: each new one narrows the previous.

:tfilter_undo  in the dir where a search started -> drop the newest layer;
               in a filtered subdir -> toggle filtering of that dir only
               (see its other files, go up, enter the next match dir);
        -a     drop every layer that covers the current dir.
"""
import os
import re
import shlex
import shutil
import subprocess
import tempfile
import threading
import time

from ranger.api.commands import Command
from ranger.container.directory import Directory
from ranger.core.loader import Loadable

ARG_BYTES = 128 * 1024  # max total size of path arguments handed to fd/rg

_stack = []  # active _Session layers, oldest first

_RULES = {
    'fd': dict(
        deny={'-x', '--exec', '-X', '--exec-batch', '-l', '--list-details',
              '-q', '--quiet', '-h', '--help', '-V', '--version', '-c',
              '--color', '--gen-completions', '--search-path',
              '--base-directory', '--format', '--path-separator',
              '--strip-cwd-prefix', '-0', '--print0'},
        short_deny='xXlqhVc0', short_val='dteESjoc',
        depth=re.compile(r'^--(max|min|exact)-?depth')),
    'rg': dict(
        deny={'-h', '--help', '-V', '--version', '--type-list',
              '--pcre2-version', '--generate', '--files', '--json'},
        short_deny='hV', short_val='ABCEMTefgjmrtd',
        depth=re.compile(r'^--max-?depth')),
}


# --- layers -----------------------------------------------------------------

class _Session:
    """One treefilter layer; also the callable put into Directory.filter_stack."""

    def __init__(self, root, allowed, full, label):
        self.root, self.allowed, self.full, self.label = root, allowed, full, label
        self.released = set()  # dirs where this layer is temporarily undone

    def __call__(self, fobj):
        return fobj.path in self.allowed

    def __str__(self):
        return 'tfilter: ' + self.label


def _within(path, root):
    return path == root or path.startswith(root.rstrip(os.sep) + os.sep)


def _live(s, path):
    """Does layer `s` filter directory `path`?"""
    if not _within(path, s.root) or path in s.released:
        return False
    p = path
    while p not in s.full:  # inside a matched dir everything is shown
        if p == s.root:
            return True
        p = os.path.dirname(p)
    return False


def _applicable(path):
    return [s for s in _stack if _live(s, path)]


_orig = getattr(Directory.refilter, '_orig', Directory.refilter)


def _refilter(self):
    stack = self.filter_stack  # other entries (:filter_stack, ...) are kept
    stack[:] = [f for f in stack if not isinstance(f, _Session)]
    stack.extend(_applicable(self.path))
    _orig(self)


_refilter._orig = _orig
Directory.refilter = _refilter


def _refresh(fm):
    for d in list(fm.directories.values()):
        d.refilter()


# --- flags and planning -----------------------------------------------------

def _scan(tool, tokens):
    """Reject unusable flags; return True if depth flags are present."""
    R, depth = _RULES[tool], False
    for tok in tokens:
        if tok == '--':
            break
        if tok.startswith('--'):
            name = tok.split('=', 1)[0]
            if name in R['deny']:
                raise ValueError('flag %s not supported' % name)
            depth = depth or bool(R['depth'].match(name))
        elif tok.startswith('-') and len(tok) > 1:
            for ch in tok[1:]:
                if ch in R['short_deny']:
                    raise ValueError('flag -%s not supported' % ch)
                depth = depth or ch == 'd'
                if ch in R['short_val']:
                    break  # rest of the token is this flag's value
    return depth


def _plan(fm, tool, tokens):
    """-> ([(cmd, only)], names): commands to run, and a top-level name
    restriction for results (None = no restriction)."""
    d = fm.thisdir
    depth = _scan(tool, tokens)
    marked = list(d.marked_items)
    chosen = marked or list(d.files)
    if not chosen:
        raise ValueError('nothing visible to search')
    paths = [f.path for f in chosen]
    unrestricted = not marked and len(chosen) == len(d.files_all or chosen)
    names = None if unrestricted else {f.basename for f in chosen}
    # Depth is relative to each search path, so with depth flags only a
    # whole-cwd search keeps the meaning.
    use_args = (not unrestricted and not depth
                and sum(len(p) + 1 for p in paths) <= ARG_BYTES)
    exe = shutil.which(tool)
    if exe is None:
        raise RuntimeError('%s not found in PATH' % tool)

    if tool == 'rg':
        tail = ['--null', '--no-messages', '--color=never']
        if '--files-without-match' not in tokens:
            tail.append('--files-with-matches')
        cmd = [exe, *tokens, *tail, '--', *(paths if use_args else ['.'])]
        return [(cmd, None)], (None if use_args else names)

    tail = ['--print0', '--color=never']
    if not use_args:
        return [([exe, *tokens, *tail], None)], names
    # fd cannot search plain files, and never tests a search path's own name:
    # one depth-1 pass in cwd covers the chosen entries themselves ...
    jobs = [([exe, *tokens, '--max-depth', '1', *tail],
             {os.path.normpath(p) for p in paths})]
    # ... and one pass over the chosen dirs covers their contents.
    dirs = [f.path for f in chosen if f.is_directory]
    if dirs:
        sp = [a for p in dirs for a in ('--search-path', p)]
        jobs.append(([exe, *tokens, *tail, *sp], None))
    return jobs, None


# --- async search -----------------------------------------------------------

class _Job:
    """One fd/rg process; stdout drained by a thread, stderr to a tempfile."""

    def __init__(self, cmd, root, only):
        self.only, self.buf, self.n = only, bytearray(), 0
        self.err = tempfile.TemporaryFile()
        self.proc = subprocess.Popen(cmd, cwd=root, stdin=subprocess.DEVNULL,
                                     stdout=subprocess.PIPE, stderr=self.err)
        self.thread = threading.Thread(target=self._drain, daemon=True)
        self.thread.start()

    def _drain(self):
        while True:
            chunk = self.proc.stdout.read1(1 << 16)
            if not chunk:
                return
            self.buf += chunk
            self.n += chunk.count(b'\0')

    @property
    def done(self):
        return self.proc.poll() is not None and not self.thread.is_alive()

    def stderr(self):
        self.err.seek(0)
        return self.err.read().decode(errors='replace').strip()

    def kill(self):
        if self.proc.poll() is None:
            self.proc.kill()


class _Search(Loadable):
    """Loader item: waits for the jobs, then builds and applies the layer."""
    progressbar_supported = True  # indeterminate: fd/rg report no totals

    def __init__(self, fm, tool, root, jobs, names, label):
        Loadable.__init__(self, self._run(), 'tfilter_%s: %s' % (tool, label))
        self.fm, self.tool, self.root = fm, tool, root
        self.jobs, self.names, self.label = jobs, names, label
        self.t0 = time.monotonic()

    def destroy(self):
        for j in self.jobs:
            j.kill()

    def _ok(self, p):
        """Is `p` visible through the names restriction and older layers?"""
        parts = os.path.relpath(p, self.root).split(os.sep)
        if self.names is not None and parts[0] not in self.names:
            return False
        d = self.root
        for part in parts:
            c = os.path.join(d, part)
            if any(c not in s.allowed for s in _applicable(d)):
                return False
            d = c
        return True

    def _run(self):
        ok_codes = (0, 1) if self.tool == 'rg' else (0,)  # rg: 1 = no match
        while not all(j.done for j in self.jobs):
            t = time.monotonic() - self.t0
            self.percent = 100 * abs(t % 2 - 1)  # bouncing bar
            self.description = 'tfilter_%s: %d found, %.1fs' % (
                self.tool, sum(j.n for j in self.jobs), t)
            time.sleep(0.005)
            yield
        for j in self.jobs:
            if j.proc.returncode not in ok_codes and not j.buf:
                self.fm.notify('tfilter_%s: %s' % (
                    self.tool, j.stderr() or 'failed'), bad=True)
                return
        matches, full, n = [], set(), 0
        for j in self.jobs:
            for raw in bytes(j.buf).split(b'\0'):
                n += 1
                if n % 2048 == 0:
                    yield
                if not raw:
                    continue
                p = os.path.normpath(os.path.join(self.root, os.fsdecode(raw)))
                if (j.only is None or p in j.only) and self._ok(p):
                    matches.append(p)
                    if self.tool == 'fd' and os.path.isdir(p):
                        full.add(p)  # matched dir: show it whole
        if not matches:
            self.fm.notify('tfilter_%s: no matches' % self.tool, bad=True)
            return
        allowed = set()
        for p in matches:
            allowed.add(p)
            p = os.path.dirname(p)
            while p != self.root and p not in allowed:
                allowed.add(p)
                p = os.path.dirname(p)
        _stack.append(_Session(self.root, allowed, full, self.label))
        _refresh(self.fm)
        self.fm.notify('tfilter_%s: %d matches in %.1fs' % (
            self.tool, len(matches), time.monotonic() - self.t0))


def _start(cmd, tool):
    fm = cmd.fm
    jobs = []
    try:
        tokens = shlex.split(cmd.rest(1))
        if not tokens:
            raise ValueError('usage: tfilter_%s [%s flags] PATTERN' % (tool, tool))
        specs, names = _plan(fm, tool, tokens)
        root = fm.thisdir.path
        for c, only in specs:
            jobs.append(_Job(c, root, only))
    except (ValueError, RuntimeError, OSError) as e:
        for j in jobs:
            j.kill()
        return fm.notify('tfilter_%s: %s' % (tool, e), bad=True)
    fm.loader.add(_Search(fm, tool, root, jobs, names, shlex.join(tokens)))
    fm.notify('tfilter_%s: searching (^C aborts)' % tool)


class tfilter_fd(Command):
    """:tfilter_fd [fd flags] [PATTERN]

    Filter the tree to entries whose names match (fd). Scope: marked entries,
    else what the current dir shows. fd's default ignore/hidden rules apply
    (use -H/-I/-u). Matched dirs are shown whole.
    """

    def execute(self):
        _start(self, 'fd')


class tfilter_rg(Command):
    """:tfilter_rg [rg flags] PATTERN

    Filter the tree to files whose contents match (rg -l). Scope: marked
    entries, else what the current dir shows. --files-without-match inverts.
    """

    def execute(self):
        _start(self, 'rg')


class tfilter_undo(Command):
    """:tfilter_undo [-a]

    Search root: drop the newest layer. Filtered subdir: toggle filtering of
    that dir only. -a: drop all layers covering the current dir.
    """

    def execute(self):
        fm, path = self.fm, self.fm.thisdir.path
        within = [s for s in _stack if _within(path, s.root)]
        here = [s for s in within if s.root == path]
        if not within:
            return fm.notify('tfilter: nothing to undo', bad=True)
        if '-a' in self.args[1:]:
            for s in within:
                _stack.remove(s)
        elif here:
            _stack.remove(here[-1])
        elif all(path in s.released for s in within):
            for s in within:
                s.released.discard(path)
        else:
            for s in within:
                s.released.add(path)
        _refresh(fm)
