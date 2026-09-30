#!/usr/bin/env python3.14
"""Persistent tmux executor. See tmux-jobs.py.md for recovery guarantees."""

from __future__ import annotations

import argparse
import fcntl
import json
import os
import re
import select
import shlex
import shutil
import signal
import sqlite3
import subprocess
import sys
import time
import uuid
from contextlib import closing, contextmanager
from pathlib import Path

SELF = Path(__file__).resolve()
ACTIVE = "('starting','running','held')"


@contextmanager
def lock(path: Path, blocking: bool = True):
    with path.open("a") as handle:
        try:
            fcntl.flock(handle, fcntl.LOCK_EX | (0 if blocking else fcntl.LOCK_NB))
        except BlockingIOError:
            yield False
            return
        try:
            yield handle
        finally:
            fcntl.flock(handle, fcntl.LOCK_UN)


class Store:
    def __init__(self, directory: Path):
        self.directory = directory
        directory.mkdir(parents=True, exist_ok=True, mode=0o700)
        self.db = sqlite3.connect(
            directory / "jobs.sqlite3", timeout=30, isolation_level=None
        )
        self.db.row_factory = sqlite3.Row
        self.db.execute("PRAGMA journal_mode=WAL")
        self.db.execute("PRAGMA synchronous=FULL")
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS settings (key TEXT PRIMARY KEY, value TEXT NOT NULL);
            INSERT OR IGNORE INTO settings VALUES ('mode','blocking'),('stop','0'),('jobs','4');
            CREATE TABLE IF NOT EXISTS jobs (
                id INTEGER PRIMARY KEY AUTOINCREMENT, argv TEXT NOT NULL,
                cwd TEXT NOT NULL, env TEXT NOT NULL, added REAL NOT NULL,
                capture INTEGER NOT NULL, state TEXT NOT NULL DEFAULT 'queued',
                token TEXT, pane TEXT, started REAL, duration REAL, rc INTEGER,
                interrupted INTEGER NOT NULL DEFAULT 0);
            CREATE INDEX IF NOT EXISTS jobs_state ON jobs(state,id);
        """)

    @contextmanager
    def transaction(self):
        self.db.execute("BEGIN IMMEDIATE")
        try:
            yield
        except BaseException:
            self.db.execute("ROLLBACK")
            raise
        else:
            self.db.execute("COMMIT")

    def get(self, key):
        return self.db.execute(
            "SELECT value FROM settings WHERE key=?", (key,)
        ).fetchone()[0]

    def set(self, key, value):
        self.db.execute(
            "INSERT OR REPLACE INTO settings VALUES (?,?)", (key, str(value))
        )

    def rows(self, where="1"):
        return self.db.execute(
            f"SELECT * FROM jobs WHERE {where} ORDER BY id"
        ).fetchall()

    def enqueue(self, commands, capture=False, unique=False):
        now = time.time()
        # Capture submission context, not the long-lived tmux server's environment.
        env = json.dumps(dict(os.environ))
        with self.transaction():
            for argv in commands:
                if (
                    unique
                    and self.db.execute(
                        f"SELECT 1 FROM jobs WHERE argv=? AND cwd=? AND (state='queued' OR state IN {ACTIVE})",
                        (json.dumps(argv), os.getcwd()),
                    ).fetchone()
                ):
                    continue
                self.db.execute(
                    "INSERT INTO jobs(argv,cwd,env,added,capture) VALUES(?,?,?,?,?)",
                    (json.dumps(argv), os.getcwd(), env, now, capture),
                )

    def finish(self, job, rc, interrupted=False):
        self.db.execute(
            """UPDATE jobs SET state='done', rc=?, duration=?, interrupted=?
                           WHERE id=? AND token=? AND state IN ('starting','running')""",
            (
                rc,
                max(0, time.time() - (job["started"] or time.time())),
                interrupted,
                job["id"],
                job["token"],
            ),
        )

    def export_logs(self):
        # SQLite is authoritative. Snapshots cannot duplicate completion records.
        version = (
            self.db.total_changes,
            self.db.execute("PRAGMA data_version").fetchone()[0],
        )
        if getattr(self, "_exported_version", None) == version:
            return
        for name, condition in [("success", "rc=0"), ("failure", "rc!=0")]:
            tmp = self.directory / f".{name}.log.tmp"
            with tmp.open("w", errors="backslashreplace") as output:
                for row in self.rows(condition):
                    command = shlex.join(json.loads(row["argv"]))
                    # Keep one physical log line even for arguments containing newlines.
                    command = command.replace("\n", r"\n").replace("\r", r"\r")
                    suffix = (
                        f" rc={row['rc']} interrupted" if row["interrupted"] else ""
                    )
                    output.write(
                        f"{row['started'] or 0:.3f} {row['duration'] or 0:.3f} "
                        f"{row['added']:.3f} {command}{suffix}\n"
                    )
            os.replace(tmp, self.directory / f"{name}.log")
        self._exported_version = version


def tmux(*args, check=True):
    return subprocess.run(
        ["tmux", *map(str, args)],
        check=check,
        text=True,
        errors="replace",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=15,
    )


def panes(session):
    result = tmux(
        "list-panes",
        "-s",
        "-t",
        "=" + session,
        "-F",
        "#{pane_id}\t#{pane_dead}\t#{pane_start_command}",
        check=False,
    )
    if result.returncode:
        if tmux("has-session", "-t", "=" + session, check=False).returncode:
            return {}
        raise RuntimeError(result.stderr.strip())
    return {
        parts[0]: parts[2]
        for line in result.stdout.splitlines()
        if len(parts := line.split("\t", 2)) == 3 and parts[1] == "0"
    }


def notify(message):
    if executable := shutil.which("dunstify"):
        try:
            subprocess.run(
                [executable, "tmux-jobs.py: " + message],
                timeout=3,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except (OSError, subprocess.TimeoutExpired):
            pass


def reconcile(store, session, recovery=False):
    live = panes(session)
    with store.transaction():
        for job in store.rows(f"state IN {ACTIVE}"):
            if any(job["token"] in cmd for cmd in live.values()):
                continue
            if job["state"] == "held":
                store.db.execute(
                    "UPDATE jobs SET state='done' WHERE id=?", (job["id"],)
                )
            elif recovery:
                store.db.execute(
                    "UPDATE jobs SET state='queued', token=NULL, pane=NULL WHERE id=?",
                    (job["id"],),
                )
            else:
                store.finish(job, 137, interrupted=True)


def launch_job(store, session, job):
    token = uuid.uuid4().hex
    store.db.execute(
        "UPDATE jobs SET state='starting', token=?, started=?, rc=NULL, "
        "duration=NULL, interrupted=0, pane=NULL WHERE id=?",
        (token, time.time(), job["id"]),
    )
    argv = [
        sys.executable,
        str(SELF),
        "--run-job",
        str(store.directory),
        str(job["id"]),
        token,
    ]
    try:
        result = tmux(
            "split-window",
            "-d",
            "-t",
            os.environ["TMUX_PANE"],
            "-P",
            "-F",
            "#{pane_id}",
            "-c",
            job["cwd"],
            "--",
            *argv,
            check=False,
        )
        if result.returncode:
            result = tmux(
                "new-window",
                "-d",
                "-t",
                session + ":",
                "-P",
                "-F",
                "#{pane_id}",
                "-c",
                job["cwd"],
                "--",
                *argv,
            )
    except (subprocess.SubprocessError, OSError):
        # A timed-out request may have created a pane: recovery must check its token.
        raise
    pane = result.stdout.strip()
    store.db.execute(
        "UPDATE jobs SET pane=? WHERE id=? AND token=?", (pane, job["id"], token)
    )
    title = f"job {job['id']}: {json.loads(job['argv'])[-1]}"
    tmux("select-pane", "-t", pane, "-T", title, check=False)
    tmux("select-layout", "-t", os.environ["TMUX_PANE"], "even-vertical", check=False)
    print(f"started job={job['id']} pane={pane}", flush=True)


def worker(directory, session):
    store = Store(Path(directory))
    with (
        closing(store.db),
        lock(store.directory / "coordinator.lock", blocking=False) as acquired,
    ):
        if not acquired:
            return 0
        store.set("worker", os.environ["TMUX_PANE"])
        tmux("set-option", "-p", "-t", os.environ["TMUX_PANE"], "remain-on-exit", "off")
        tmux(
            "select-pane",
            "-t",
            os.environ["TMUX_PANE"],
            "-T",
            "queue-worker",
            check=False,
        )
        reconcile(store, session, recovery=True)
        previous_failures = len(store.rows("rc!=0"))
        while True:
            reconcile(store, session)
            # Serialize dispatch, stop/kill, and idle exit with submissions.
            with lock(store.directory / "launch.lock"):
                active = len(store.rows(f"state IN {ACTIVE}"))
                if store.get("stop") == "0":
                    for job in store.rows("state='queued'")[
                        : max(0, int(store.get("jobs")) - active)
                    ]:
                        launch_job(store, session, job)
                if not store.rows(f"state IN {ACTIVE}") and (
                    store.get("stop") == "1" or not store.rows("state='queued'")
                ):
                    store.export_logs()
                    stopped = store.get("stop") == "1"
                    store.set("worker", "")
                    # Release coordinator lock before releasing launch.lock.
                    # The caller may immediately submit another batch.
                    fcntl.flock(acquired, fcntl.LOCK_UN)
                    break
                store.export_logs()
            failures = len(store.rows("rc!=0"))
            if failures > previous_failures:
                notify(f"{failures - previous_failures} job(s) failed")
                previous_failures = failures
            time.sleep(0.2)
    # Launchers also check worker marker: an exiting coordinator is never reused.
    notify("queue stopped" if stopped else "queue finished")
    return 0


def run_job(directory, identity, token):
    store = Store(Path(directory))
    with closing(store.db):
        return execute_job(store, identity, token)


def execute_job(store, identity, token):
    pane = os.environ["TMUX_PANE"]
    with store.transaction():
        job = store.db.execute(
            "SELECT * FROM jobs WHERE id=? AND token=? AND state='starting'",
            (identity, token),
        ).fetchone()
        if job is None:
            return 0
        store.db.execute(
            "UPDATE jobs SET state='running', pane=?, started=? WHERE id=?",
            (pane, time.time(), identity),
        )
    tmux("set-option", "-p", "-t", pane, "remain-on-exit", "off")
    environment = json.loads(job["env"])
    for name in ("TMUX", "TMUX_PANE", "TERM"):
        if name in os.environ:
            environment[name] = os.environ[name]
    child = None

    def interrupted(signum, frame):
        if child is not None:
            try:
                os.killpg(child.pid, signal.SIGTERM)
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait()
            except ProcessLookupError:
                pass
        raise SystemExit(128 + signum)

    for sig in (signal.SIGHUP, signal.SIGTERM, signal.SIGINT):
        signal.signal(sig, interrupted)
    start = time.monotonic()
    try:
        child = subprocess.Popen(
            json.loads(job["argv"]),
            cwd=job["cwd"],
            env=environment,
            start_new_session=True,
        )
        rc = child.wait()
        rc = rc if rc >= 0 else 128 - rc
    except OSError as error:
        print(f"cannot execute: {error}", file=sys.stderr, flush=True)
        rc = 127
    if rc or job["capture"]:
        logdir = store.directory / ("err" if rc else "out")
        logdir.mkdir(exist_ok=True)
        capture = tmux("capture-pane", "-p", "-t", pane, "-S", "-", check=False)
        (logdir / f"job{identity}_{token}.log").write_text(capture.stdout)
    with store.transaction():
        changed = store.db.execute(
            "UPDATE jobs SET state=?, rc=?, duration=? "
            "WHERE id=? AND token=? AND state='running'",
            ("held" if rc else "done", rc, time.monotonic() - start, identity, token),
        ).rowcount
    if not changed:
        return 0
    if rc:
        print(
            f"Job {identity} failed (rc={rc}). Press ENTER to release slot.", flush=True
        )
        while store.get("mode") != "continue":
            current = store.db.execute(
                "SELECT state,token FROM jobs WHERE id=?", (identity,)
            ).fetchone()
            if current["state"] != "held" or current["token"] != token:
                return 0
            if sys.stdin.isatty() and select.select([sys.stdin], [], [], 0.2)[0]:
                if sys.stdin.readline():
                    break
            else:
                time.sleep(0.2)
        store.db.execute(
            "UPDATE jobs SET state='done' WHERE id=? AND token=? AND state='held'",
            (identity, token),
        )
    # Return zero so user remain-on-exit=failed settings cannot retain failed wrappers.
    return 0


def ensure_worker(store, session):
    """Called under launch.lock. Worker starts without taking that lock."""
    marker = store.db.execute(
        "SELECT value FROM settings WHERE key='worker'"
    ).fetchone()
    live = panes(session)
    if marker and "--worker" in live.get(marker[0], ""):
        with lock(store.directory / "coordinator.lock", blocking=False) as free:
            if not free:
                return
    args = [sys.executable, str(SELF), "--worker", str(store.directory), session]
    exists = tmux("has-session", "-t", "=" + session, check=False).returncode == 0
    if exists:
        owner = tmux(
            "show-options", "-qv", "-t", "=" + session, "@tmux-jobs-python"
        ).stdout.strip()
        if owner != str(store.directory):
            raise RuntimeError(
                f"session {session!r} belongs to another executor; choose -s NAME"
            )
        result = tmux(
            "new-window",
            "-d",
            "-t",
            session + ":",
            "-P",
            "-F",
            "#{pane_id}",
            "--",
            *args,
        )
    else:
        result = tmux(
            "new-session", "-d", "-s", session, "-P", "-F", "#{pane_id}", "--", *args
        )
        tmux("set-option", "-t", "=" + session, "@tmux-jobs-python", store.directory)
    pane = result.stdout.strip()
    deadline = time.monotonic() + 10
    while time.monotonic() < deadline:
        marker = store.db.execute(
            "SELECT value FROM settings WHERE key='worker'"
        ).fetchone()
        if marker and marker[0] == pane:
            return
        time.sleep(0.05)
    raise RuntimeError("coordinator did not start; queued jobs remain recoverable")


def check_owner(store, session):
    if tmux("has-session", "-t", "=" + session, check=False).returncode == 0:
        owner = tmux(
            "show-options", "-qv", "-t", "=" + session, "@tmux-jobs-python"
        ).stdout.strip()
        if owner != str(store.directory):
            raise RuntimeError(
                f"session {session!r} belongs to another executor; choose -s NAME"
            )


def records(stream, delimiter):
    pending = b""
    while chunk := stream.read(65536):
        parts = (pending + chunk).split(delimiter)
        pending = parts.pop()
        for part in parts:
            yield os.fsdecode(part)
    if pending:
        yield os.fsdecode(pending)


def parser():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        "-j",
        type=int,
        default=None,
        help="concurrent jobs (default: 4 for new session)",
    )
    p.add_argument("-s", default="jobs", help="tmux session name")
    p.add_argument(
        "-0", dest="delimiter", action="store_const", const=b"\0", default=b"\0"
    )
    p.add_argument("-1", dest="delimiter", action="store_const", const=b"\n")
    p.add_argument("-n", action="store_true", help="dry run; no state changes")
    p.add_argument("-O", action="store_true", help="capture successful pane output")
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("-c", dest="mode", action="store_const", const="continue")
    mode.add_argument("-C", dest="mode", action="store_const", const="blocking")
    stop = p.add_mutually_exclusive_group()
    stop.add_argument(
        "-k", action="store_true", help="drain active jobs; preserve queue"
    )
    stop.add_argument(
        "-K", action="store_true", help="kill active jobs; preserve unfinished work"
    )
    p.add_argument("-x", action="store_true", help="print submitted commands")
    p.add_argument(
        "--unique", action="store_true", help="skip identical pending argv/cwd records"
    )
    p.add_argument("command", nargs=argparse.REMAINDER)
    return p


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv[:1] == ["--worker"]:
        return worker(*argv[1:])
    if argv[:1] == ["--run-job"]:
        return run_job(*argv[1:])
    p = parser()
    args = p.parse_args(argv)
    if not re.fullmatch(r"[A-Za-z0-9_-]+", args.s):
        p.error("session must contain only letters, digits, underscores or hyphens")
    if args.j is not None and args.j < 1:
        p.error("-j must be positive")
    command = args.command[1:] if args.command[:1] == ["--"] else args.command
    commands = []
    if not (args.k or args.K) and not sys.stdin.isatty():
        commands = [
            (command + [record] if command else ["bash", "-xec", record])
            for record in records(sys.stdin.buffer, args.delimiter)
            if command or record
        ]
    if args.n or args.x:
        for command in commands:
            print(shlex.join(command))
    if args.n:
        return 0
    if not shutil.which("tmux"):
        p.error("tmux not found on PATH")
    directory = (
        Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")).absolute()
        / "tmux"
        / args.s
        / "python"
    )
    os.umask(0o077)
    store = Store(directory)
    with closing(store.db), lock(directory / "launch.lock"):
        check_owner(store, args.s)
        if args.mode:
            store.set("mode", args.mode)
        if args.j is not None:
            store.set("jobs", args.j)
        if args.k or args.K:
            store.set("stop", 1)
            if args.K:
                live = panes(args.s)
                active = store.rows(f"state IN {ACTIVE}")
                with store.transaction():
                    store.db.execute(
                        "UPDATE jobs SET state='queued',token=NULL,pane=NULL "
                        "WHERE state IN ('starting','running')"
                    )
                    store.db.execute("UPDATE jobs SET state='done' WHERE state='held'")
                for pane, cmd in live.items():
                    if any(job["token"] in cmd for job in active):
                        tmux("kill-pane", "-t", pane, check=False)
                marker = store.db.execute(
                    "SELECT value FROM settings WHERE key='worker'"
                ).fetchone()
                if marker and "--worker" in live.get(marker[0], ""):
                    tmux("kill-pane", "-t", marker[0], check=False)
                store.set("worker", "")
                store.export_logs()
            return 0
        if commands:
            store.enqueue(commands, args.O, args.unique)
        if commands or args.mode == "continue" or args.mode is None:
            store.set("stop", 0)
            if store.rows(f"state='queued' OR state IN {ACTIVE}"):
                ensure_worker(store, args.s)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
    except (OSError, RuntimeError, sqlite3.Error, subprocess.SubprocessError) as error:
        print(f"tmux-jobs.py: {error}", file=sys.stderr)
        sys.exit(1)
