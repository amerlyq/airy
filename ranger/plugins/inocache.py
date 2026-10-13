"""inocache: reusable SQLite stores with independent schemas and validity rules.

Distinct caches (mediainfo, diskinfo, fpcalc, tags, visited...) must not share a schema or a
version: bumping fpcalc's parser must not drop 300k mediainfo rows. Stores can use separate files
or separate tables in one shared database. Each table owns its VERSION and validity rule:

  validate="file"   key = inode, row valid while (mtime_ns, size) match   (mediainfo, fpcalc, diskinfo)
  validate="dir"    key = inode, row valid while mtime_ns matches          (directory aggregates)
  validate="none"   key = inode, never invalidated                         (user tags: survive edits)
  validate="path"   key = path string, never invalidated                   (visited dirs)

  s = Store("fpcalc", version=1)
  s.get(st)            -> value | None        st = os.stat() result (or a path for "path" stores)
  s.get_many(sts)      -> {key: value}        ONE sql query per 500 keys
  s.put(st, value)     value: anything marshal can dump (tuple/list/dict/str/int/None)
  optional range_index(value) adds an integer index; query_range(lo, hi) returns indexed rows
  s.flush()            persist pending rows (also atexit, and every FLUSH_EVERY puts)

Memo + pending rows live in-process; sqlite connections are per thread; fork drops them.
Best-effort: any sqlite error degrades to a miss, never an exception into ranger.
EXTEND: another validity rule -> add a branch in Store._stamp and _key.
"""

# Stores default to separate sqlite files.
# Related stores can share a database while retaining independent tables and versions.

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
        range_index=None,
        database: str | None = None,
    ) -> None:
        assert validate in ("file", "dir", "none", "path"), validate
        self.name, self.version, self.validate = name, version, validate
        self.range_index = range_index
        self.shared_database = database is not None
        self.path = database or os.path.join(root or ROOT, name + ".sqlite3")
        safe_name = "".join(ch if ch.isalnum() or ch == "_" else "_" for ch in name)
        self.table = (
            f"s_{safe_name}_{crc32(name.encode()) & 0xFFFFFFFF:08x}"
            if self.shared_database
            else "v"
        )
        self.flush_every = FLUSH_EVERY
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
            os.makedirs(os.path.dirname(self.path) or ".", exist_ok=True)
            c = sqlite3.connect(self.path, timeout=10, isolation_level=None)
            try:
                c.execute("PRAGMA journal_mode=WAL")
            except sqlite3.Error:
                pass
            c.execute("PRAGMA synchronous=NORMAL")
            schema = f"{self.version}:{self.validate}"
            if self.range_index:
                schema += ":range"
            want = crc32(schema.encode()) & 0x7FFFFFFF
            kt = "TEXT" if self.validate == "path" else "INTEGER"
            with self._slock:
                if self.shared_database:
                    c.execute(
                        "CREATE TABLE IF NOT EXISTS inocache_schema "
                        "(name TEXT PRIMARY KEY, version INTEGER NOT NULL)"
                    )
                    c.execute("BEGIN IMMEDIATE")
                    row = c.execute(
                        "SELECT version FROM inocache_schema WHERE name=?",
                        (self.name,),
                    ).fetchone()
                    if row is None or row[0] != want:
                        c.execute(f"DROP TABLE IF EXISTS {self.table}")
                        columns = f"k {kt} PRIMARY KEY, mt INTEGER, sz INTEGER"
                        if self.range_index:
                            columns += ", idx INTEGER"
                        columns += ", blob BLOB"
                        c.execute(f"CREATE TABLE {self.table}({columns})")
                        if self.range_index:
                            c.execute(
                                f"CREATE INDEX {self.table}_idx ON {self.table}(idx)"
                            )
                        c.execute(
                            "INSERT OR REPLACE INTO inocache_schema VALUES (?,?)",
                            (self.name, want),
                        )
                    c.execute("COMMIT")
                elif c.execute("PRAGMA user_version").fetchone()[0] != want:
                    c.execute("BEGIN IMMEDIATE")
                    if c.execute("PRAGMA user_version").fetchone()[0] != want:  # raced?
                        c.execute(f"DROP TABLE IF EXISTS {self.table}")
                        columns = "k %s PRIMARY KEY, mt INTEGER, sz INTEGER" % kt
                        if self.range_index:
                            columns += ", idx INTEGER"
                        columns += ", blob BLOB"
                        c.execute(f"CREATE TABLE {self.table}({columns})")
                        if self.range_index:
                            c.execute(f"CREATE INDEX {self.table}_idx ON {self.table}(idx)")
                        c.execute(f"PRAGMA user_version={want}")
                    c.execute("COMMIT")
            self._tl.c = c
        return c

    # -- api ------------------------------------------------------------------ #

    def get(self, st):
        return self.get_with_status(st)[0]

    def get_with_status(self, st):
        """-> (value, found); found distinguishes a cached None from a miss."""
        key = self._key(st)
        row = self._mem.get(key)
        if row is None:
            try:
                r = (
                    self._db().execute(
                        f"SELECT mt,sz,blob FROM {self.table} WHERE k=?", (key,)
                    )
                    .fetchone()
                )
            except sqlite3.Error:
                r = None
            row = self._mem[key] = (
                (r[0], r[1], marshal.loads(r[2])) if r else (None, None, _MISS)
            )
        mt, sz, value = row
        if value is _MISS:
            return None, False
        if self.validate in ("file", "dir") and (mt, sz) != self._stamp(st):
            return None, False
        return value, True

    def _valid(self, row, st):
        mt, sz, value = row
        if value is _MISS:
            return None
        if self.validate in ("file", "dir") and (mt, sz) != self._stamp(st):
            return None
        return value

    def get_many(self, sts) -> dict:
        return {k: row[2] for k, row in self.get_many_records(sts).items()}

    def get_many_records(self, sts) -> dict:
        """-> {key: (stored_mtime, stored_size, value)} for valid requested keys."""
        sts = list(sts)
        need = [self._key(s) for s in sts if self._key(s) not in self._mem]
        if need:
            try:
                c = self._db()
                for i in range(0, len(need), 500):
                    part = need[i : i + 500]
                    q = f"SELECT k,mt,sz,blob FROM {self.table} WHERE k IN (%s)" % ",".join(
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
            row = self._mem[self._key(s)]
            mt, sz, value = row
            if value is not _MISS and (
                self.validate not in ("file", "dir") or (mt, sz) == self._stamp(s)
            ):
                out[self._key(s)] = row
        return out

    def query_range(self, low: int, high: int) -> dict:
        """-> {key: (mt, sz, value)} for values whose configured integer index is in range."""
        if self.range_index is None:
            raise ValueError("query_range requires range_index")
        try:
            rows = self._db().execute(
                f"SELECT k,mt,sz,blob FROM {self.table} WHERE idx BETWEEN ? AND ?",
                (low, high),
            )
            out = {}
            for key, mt, sz, blob in rows:
                row = (mt, sz, marshal.loads(blob))
                self._mem[key] = row
                out[key] = row
            return out
        except sqlite3.Error:
            return {}

    def put(self, st, value) -> None:
        key = self._key(st)
        mt, sz = self._stamp(st)
        row = self._mem[key] = (mt, sz, value)
        with self._lock:
            self._new[key] = row
            full = len(self._new) >= self.flush_every
        if full:
            self.flush()

    def flush(self) -> None:
        with self._lock:
            if not self._new:
                return
            if self.range_index:
                rows = [
                    (k, r[0], r[1], self.range_index(r[2]), marshal.dumps(r[2]))
                    for k, r in self._new.items()
                ]
            else:
                rows = [(k, r[0], r[1], marshal.dumps(r[2])) for k, r in self._new.items()]
            self._new.clear()
        try:
            with self._wlock:
                c = self._db()
                c.execute("BEGIN IMMEDIATE")
                try:
                    placeholders = "?,?,?,?,?" if self.range_index else "?,?,?,?"
                    c.executemany(
                        f"INSERT OR REPLACE INTO {self.table} VALUES ({placeholders})", rows
                    )
                    c.execute("COMMIT")
                except BaseException:
                    c.execute("ROLLBACK")
                    raise
        except Exception:  # locked / disk full: keep for the next flush
            with self._lock:
                for row in rows:
                    k, mt, sz = row[:3]
                    blob = row[-1]
                    self._new.setdefault(k, (mt, sz, marshal.loads(blob)))

    def _after_fork(self) -> None:
        self._tl = threading.local()  # never share a sqlite connection with the parent
        self._lock, self._wlock, self._slock = (threading.Lock() for _ in range(3))
        self._mem.clear()
        self._new.clear()


def flush_all() -> None:
    for store in _ALL:
        store.flush()


atexit.register(flush_all)
os.register_at_fork(after_in_child=lambda: [s._after_fork() for s in _ALL])
