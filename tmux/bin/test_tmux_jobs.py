"""Run: python3.14 -m unittest discover -s tmux/bin -p 'test_*.py'."""

import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "tmux_jobs", Path(__file__).with_name("tmux-jobs.py")
)
jobs = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(jobs)


class QueueTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.store = jobs.Store(Path(self.tmp.name))
        self.addCleanup(self.store.db.close)

    def running(self, state="running"):
        self.store.enqueue([["echo", "hello"]])
        self.store.db.execute(
            "UPDATE jobs SET state=?, token=?, pane=?, started=1",
            (state, "attempt123", "%42"),
        )
        return self.store.rows()[0]

    def test_records_keep_unterminated_and_special_arguments(self):
        raw = b"one\0two\nthree\0-$(touch nope)\0last"
        self.assertEqual(
            list(jobs.records(io.BytesIO(raw), b"\0")),
            ["one", "two\nthree", "-$(touch nope)", "last"],
        )

    def test_empty_xargs_records_are_preserved(self):
        self.assertEqual(
            list(jobs.records(io.BytesIO(b"\0a\0\0"), b"\0")), ["", "a", ""]
        )

    def test_argv_roundtrip_and_distinct_duplicate_ids(self):
        argv = ["printf", "%s", 'line\n"quote";$(false)']
        self.store.enqueue([argv, argv])
        rows = self.store.rows()
        self.assertEqual(len(rows), 2)
        self.assertNotEqual(rows[0]["id"], rows[1]["id"])
        self.assertEqual(json.loads(rows[0]["argv"]), argv)

    def test_unique_only_deduplicates_unfinished_jobs(self):
        self.store.enqueue([["true"], ["true"]], unique=True)
        self.assertEqual(len(self.store.rows()), 1)
        self.store.db.execute("UPDATE jobs SET state='done'")
        self.store.enqueue([["true"]], unique=True)
        self.assertEqual(len(self.store.rows()), 2)

    def test_transaction_rolls_back_batch(self):
        with self.assertRaises(RuntimeError):
            with self.store.transaction():
                self.store.set("mode", "continue")
                raise RuntimeError("crash")
        self.assertEqual(self.store.get("mode"), "blocking")

    def test_recovery_adopts_existing_token_before_registration(self):
        self.running("starting")
        with patch.object(
            jobs, "panes", return_value={"%99": "python --run-job attempt123"}
        ):
            jobs.reconcile(self.store, "test", recovery=True)
        self.assertEqual(self.store.rows()[0]["state"], "starting")

    def test_recovery_requeues_missing_running_job(self):
        self.running()
        with patch.object(jobs, "panes", return_value={}):
            jobs.reconcile(self.store, "test", recovery=True)
        row = self.store.rows()[0]
        self.assertEqual(row["state"], "queued")
        self.assertIsNone(row["token"])

    def test_recovery_does_not_adopt_reused_pane_id(self):
        self.running()
        with patch.object(jobs, "panes", return_value={"%42": "python --worker"}):
            jobs.reconcile(self.store, "test", recovery=True)
        self.assertEqual(self.store.rows()[0]["state"], "queued")

    def test_control_refuses_foreign_session(self):
        with patch.object(
            jobs, "tmux", return_value=subprocess.CompletedProcess([], 0, "foreign", "")
        ):
            with self.assertRaises(RuntimeError):
                jobs.check_owner(self.store, "test")

    def test_normal_pane_death_fails_without_retry(self):
        self.running()
        with patch.object(jobs, "panes", return_value={}):
            jobs.reconcile(self.store, "test")
        row = self.store.rows()[0]
        self.assertEqual(
            (row["state"], row["rc"], row["interrupted"]), ("done", 137, 1)
        )

    def test_held_failure_is_not_replayed_on_recovery(self):
        self.running("held")
        self.store.db.execute("UPDATE jobs SET rc=7")
        with patch.object(jobs, "panes", return_value={}):
            jobs.reconcile(self.store, "test", recovery=True)
        self.assertEqual(self.store.rows()[0]["state"], "done")
        self.assertEqual(self.store.rows()[0]["rc"], 7)

    def test_stale_attempt_cannot_complete_new_attempt(self):
        old = self.running()
        self.store.db.execute("UPDATE jobs SET token='replacement'")
        self.store.finish(old, 0)
        self.assertEqual(self.store.rows()[0]["state"], "running")

    def test_log_snapshot_is_idempotent(self):
        row = self.running()
        self.store.finish(row, 137, interrupted=True)
        self.store.export_logs()
        self.store.export_logs()
        lines = (Path(self.tmp.name) / "failure.log").read_text().splitlines()
        self.assertEqual(len(lines), 1)
        self.assertIn("rc=137 interrupted", lines[0])

    def test_runner_executes_exact_argv_in_original_context(self):
        output = Path(self.tmp.name) / "result.json"
        special = "spaces\n'quotes';$(false)"
        program = (
            "import os,sys,json; "
            'open(sys.argv[1],"w").write(json.dumps([sys.argv[2],os.getenv("QUEUE_TEST")]))'
        )
        with patch.dict(os.environ, {"QUEUE_TEST": "submitted"}):
            self.store.enqueue([[sys.executable, "-c", program, str(output), special]])
        self.store.db.execute("UPDATE jobs SET state='starting',token='abc'")
        with (
            patch.dict(os.environ, {"TMUX_PANE": "%1", "QUEUE_TEST": "server"}),
            patch.object(jobs.signal, "signal"),
            patch.object(jobs, "tmux"),
        ):
            jobs.run_job(self.tmp.name, "1", "abc")
        self.assertEqual(json.loads(output.read_text()), [special, "submitted"])
        self.assertEqual(self.store.rows()[0]["rc"], 0)

    def test_dry_run_creates_no_cache(self):
        cache = Path(self.tmp.name) / "absent"
        result = subprocess.run(
            [sys.executable, str(jobs.SELF), "-n", "--", "printf", "%s"],
            input=b"last",
            env={**os.environ, "XDG_CACHE_HOME": str(cache)},
            capture_output=True,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(b"last", result.stdout)
        self.assertFalse(cache.exists())

    def test_graceful_stop_never_dispatches_queued_jobs(self):
        self.store.enqueue([["true"]])
        self.store.set("stop", 1)
        with (
            patch.object(jobs, "panes", return_value={}),
            patch.object(jobs, "tmux"),
            patch.object(jobs, "launch_job") as launch,
            patch.object(jobs, "notify"),
            patch.dict(os.environ, {"TMUX_PANE": "%1"}),
        ):
            jobs.worker(self.tmp.name, "test")
        launch.assert_not_called()
        self.assertEqual(self.store.rows()[0]["state"], "queued")

    def test_held_failures_consume_slots(self):
        self.running("held")
        self.store.enqueue([["true"], ["true"]])
        self.store.set("jobs", 2)
        dispatched = []

        def launch(store, session, row):
            dispatched.append(row["id"])
            store.db.execute(
                "UPDATE jobs SET state='running',token='next' WHERE id=?", (row["id"],)
            )

        with (
            patch.object(jobs, "panes", return_value={"%42": "python attempt123"}),
            patch.object(jobs, "tmux"),
            patch.object(jobs, "launch_job", side_effect=launch),
            patch.object(jobs, "notify"),
            patch.object(jobs.time, "sleep", side_effect=RuntimeError("end tick")),
            patch.dict(os.environ, {"TMUX_PANE": "%1"}),
        ):
            with self.assertRaisesRegex(RuntimeError, "end tick"):
                jobs.worker(self.tmp.name, "test")
        self.assertEqual(len(dispatched), 1)


if __name__ == "__main__":
    unittest.main()
