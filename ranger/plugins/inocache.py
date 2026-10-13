"""inocache: vdprobe's cache scheme as a reusable store; ONE store = ONE sqlite file.

Distinct caches (mediainfo, diskinfo, fpcalc, tags, visited...) must not share a schema or a
version: bumping fpcalc's parser must not drop 300k mediainfo rows.  So each Store owns
`<ROOT>/<name>.sqlite3`, its own VERSION (-> PRAGMA user_version; mismatch = table recreated)
and its own validity rule:

  validate="file"   key = inode, row valid while (mtime_ns, size) match   (mediainfo, fpcalc, diskinfo)
  validate="dir"    key = inode, row valid while mtime_ns matches          (directory aggregates)
  validate="none"   key = inode, never invalidated                         (user tags: survive edits)
  validate="path"   key = path string, never invalidated                   (visited dirs)

  s = Store("fpcalc", version=1)
  s.get(st)            -> value | None        st = os.stat() result (or a path for "path" stores)
  s.get_many(sts)      -> {key: value}        ONE sql query per 500 keys
  s.put(st, value)     value: anything marshal can dump (tuple/list/dict/str/int/None)
  s.flush()            persist pending rows (also atexit, and every FLUSH_EVERY puts)

Memo + pending rows live in-process; sqlite connections are per thread; fork drops them.
Best-effort: any sqlite error degrades to a miss, never an exception into ranger.
ALT: vdprobe.py keeps its own copy of this machinery (+ CLI, forked probing, dir table `d`).
     benefit: untouched, proven on real data; migrate later by giving it Store("mediainfo", ...)
     and keeping the schema (ino, mt, sz, dur, codec) as a Store subclass.
EXTEND: another validity rule -> add a branch in Store._ok and _key (e.g. "mtime" for sidecars).
"""

# WIP:
# - `inocache.Store(name, version, validate)` gives one sqlite file per cache, each with its own version bump.
# - Validation modes are `file`, `dir`, `none` (for user tags) and `path` (for visited).
# - `vdprobe.py` is deliberately untouched; migrating it onto Store is a later step.
# - `visited` is still an in-memory set in `vdsym.py`, so persisting it would be a behavior change.

from __future__ import annotations

import atexit
import marshal
import os
import sqlite3
import threading
from zlib import crc32

ROOT = os.path.join(
    os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache"), "vd"
)
FLUSH_EVERY = 64
_MISS = object()
_ALL: list[Store] = []


class Store:
    def __init__(
        self,
        name: str,
        version: int = 1,
        validate: str = "file",
        root: str | None = None,
    ) -> None:
        assert validate in ("file", "dir", "none", "path"), validate
        self.name, self.version, self.validate = name, version, validate
        self.path = os.path.join(root or ROOT, name + ".sqlite3")
        self._mem: dict = {}  # key -> (mt, sz, value) | _MISS marker tuple
        self._new: dict = {}
        self._lock = threading.Lock()  # _new
        self._wlock = threading.Lock()  # sqlite writes
        self._slock = (
            threading.Lock()
        )  # schema (separate: flush() holds _wlock while opening)
        self._tl = threading.local()
        _ALL.append(self)

    # -- keys / validity ------------------------------------------------------ #

    def _key(self, st):
        if self.validate == "path":
            return os.fspath(st)
        return st.st_ino

    def _stamp(self, st) -> tuple[int, int]:
        if self.validate == "file":
            return st.st_mtime_ns, st.st_size
        if self.validate == "dir":
            return st.st_mtime_ns, 0
        return 0, 0  # none / path: nothing to compare

    # -- sqlite -------------------------------------------------------------- #

    def _db(self) -> sqlite3.Connection:
        c = getattr(self._tl, "c", None)
        if c is None:
            os.makedirs(os.path.dirname(self.path), exist_ok=True)
            c = sqlite3.connect(self.path, timeout=10, isolation_level=None)
            try:
                c.execute("PRAGMA journal_mode=WAL")
            except sqlite3.Error:
                pass
            c.execute("PRAGMA synchronous=NORMAL")
            want = crc32(f"{self.version}:{self.validate}".encode()) & 0x7FFFFFFF
            kt = "TEXT" if self.validate == "path" else "INTEGER"
            with self._slock:
                if c.execute("PRAGMA user_version").fetchone()[0] != want:
                    c.execute("BEGIN IMMEDIATE")
                    if c.execute("PRAGMA user_version").fetchone()[0] != want:  # raced?
                        c.execute("DROP TABLE IF EXISTS v")
                        c.execute(
                            f"CREATE TABLE v(k {kt} PRIMARY KEY, mt INTEGER, sz INTEGER, blob BLOB)"
                        )
                        c.execute(f"PRAGMA user_version={want}")
                    c.execute("COMMIT")
            self._tl.c = c
        return c

    # -- api ------------------------------------------------------------------ #

    def get(self, st):
        key = self._key(st)
        row = self._mem.get(key)
        if row is None:
            try:
                r = (
                    self._db()
                    .execute("SELECT mt,sz,blob FROM v WHERE k=?", (key,))
                    .fetchone()
                )
            except sqlite3.Error:
                r = None
            row = self._mem[key] = (
                (r[0], r[1], marshal.loads(r[2])) if r else (None, None, _MISS)
            )
        return self._valid(row, st)

    def _valid(self, row, st):
        mt, sz, value = row
        if value is _MISS:
            return None
        if self.validate in ("file", "dir") and (mt, sz) != self._stamp(st):
            return None
        return value

    def get_many(self, sts) -> dict:
        sts = list(sts)
        need = [self._key(s) for s in sts if self._key(s) not in self._mem]
        if need:
            try:
                c = self._db()
                for i in range(0, len(need), 500):
                    part = need[i : i + 500]
                    q = "SELECT k,mt,sz,blob FROM v WHERE k IN (%s)" % ",".join(
                        "?" * len(part)
                    )
                    for k, mt, sz, blob in c.execute(q, part):
                        self._mem[k] = (mt, sz, marshal.loads(blob))
            except sqlite3.Error:
                pass
            for k in need:
                self._mem.setdefault(k, (None, None, _MISS))
        out = {}
        for s in sts:
            v = self._valid(self._mem[self._key(s)], s)
            if v is not None:
                out[self._key(s)] = v
        return out

    def put(self, st, value) -> None:
        key = self._key(st)
        mt, sz = self._stamp(st)
        row = self._mem[key] = (mt, sz, value)
        with self._lock:
            self._new[key] = row
            full = len(self._new) >= FLUSH_EVERY
        if full:
            self.flush()

    def flush(self) -> None:
        with self._lock:
            if not self._new:
                return
            rows = [(k, r[0], r[1], marshal.dumps(r[2])) for k, r in self._new.items()]
            self._new.clear()
        try:
            with self._wlock:
                c = self._db()
                c.execute("BEGIN IMMEDIATE")
                try:
                    c.executemany("INSERT OR REPLACE INTO v VALUES (?,?,?,?)", rows)
                    c.execute("COMMIT")
                except BaseException:
                    c.execute("ROLLBACK")
                    raise
        except Exception:  # locked / disk full: keep for the next flush
            with self._lock:
                for k, mt, sz, blob in rows:
                    self._new.setdefault(k, (mt, sz, marshal.loads(blob)))

    def _after_fork(self) -> None:
        self._tl = threading.local()  # never share a sqlite connection with the parent
        self._lock, self._wlock, self._slock = (threading.Lock() for _ in range(3))
        self._new.clear()


def flush_all() -> None:
    for store in _ALL:
        store.flush()


atexit.register(flush_all)
os.register_at_fork(after_in_child=lambda: [s._after_fork() for s in _ALL])
