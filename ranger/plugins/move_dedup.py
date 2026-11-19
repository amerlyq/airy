# ~/.config/ranger/plugins/move_dedup.py
#
# Move current tab's directory content into the *next* tab's directory
# without content duplicates.  Pure Python 3.14+ (no rsync/shell).
#
# Three-phase approach:
#   1. Move files whose names don't exist in dest (preserving metadata)
#   2. Delete source files that are byte-identical to their dest counterpart
#   3. Move remaining conflicts with _ and _1 suffixes
#
# Usage:  :move_dedup
# Bind:   map <key> move_dedup

from __future__ import absolute_import
import ranger.api.commands
import os
import sys

# ── Guard: pathlib.Path.move / .copy need Python ≥ 3.14 ──────────
_HAVE_PATHLIB_MOVE = False
try:
    from pathlib import Path as _P

    if hasattr(_P, "move") and hasattr(_P, "copy"):
        _HAVE_PATHLIB_MOVE = True
except Exception:
    pass


class move_dedup(ranger.api.commands.Command):
    """
    :move_dedup

    Move all content from the current directory (this tab) into the
    directory shown in the *next* tab, deduplicating:
      1. move unique-name files (preserving metadata via pathlib)
      2. delete source files that are byte-identical to dest
      3. move remaining same-name-but-different files with _ / _1 suffixes

    Requires Python ≥ 3.14 for pathlib.Path.move() / .copy().
    """

    def execute(self):
        if not _HAVE_PATHLIB_MOVE:
            v = f"{sys.version_info.major}.{sys.version_info.minor}"
            self.fm.notify(
                f"move_dedup requires Python ≥ 3.14 "
                f"(pathlib.Path.move/copy); running {v}",
                bad=True,
            )
            return

        from pathlib import Path

        # ── resolve source & destination directories ──────────────
        src_dir = Path(self.fm.thisdir.path)

        dst_dir = self._next_tab_path()
        if dst_dir is None:
            return
        dst_dir = Path(dst_dir)

        if src_dir.resolve() == dst_dir.resolve():
            self.fm.notify("Source and destination are the same directory.", bad=True)
            return

        self.fm.notify(f"move_dedup: {src_dir}  →  {dst_dir}")

        # ── Phase 1: move files whose names are unique to dest ────
        # Walk source; for each file, if no same-relpath exists in
        # dest, move it (preserving metadata).
        phase1_moved = 0
        phase2_removed = 0
        remaining = []  # list of (src_abs: Path, rel: PurePosixPath)

        # Snapshot the tree first so we don't mutate while iterating
        src_files = sorted(src_dir.rglob("*"))
        src_files = [p for p in src_files if p.is_file(follow_symlinks=False)]

        for src_file in src_files:
            rel = src_file.relative_to(src_dir)
            dst_file = dst_dir / rel

            if not dst_file.exists():
                # Unique name → move directly (preserves metadata)
                dst_file.parent.mkdir(parents=True, exist_ok=True)
                src_file.move(dst_file)
                phase1_moved += 1
            else:
                remaining.append((src_file, rel))

        # ── Phase 2: remove byte-identical duplicates ─────────────
        still_remaining = []
        for src_file, rel in remaining:
            dst_file = dst_dir / rel
            if dst_file.is_file() and self._files_identical(src_file, dst_file):
                src_file.unlink()
                phase2_removed += 1
            else:
                still_remaining.append((src_file, rel))

        # ── Phase 3: suffix-rename conflicting files ──────────────
        phase3_moved = 0
        for src_file, rel in still_remaining:
            dst_file = dst_dir / rel
            dst_file.parent.mkdir(parents=True, exist_ok=True)

            # Incoming source → "name.ext_"
            suffixed = dst_file.parent / (dst_file.name + "_")
            if not suffixed.exists():
                src_file.move(suffixed)
                # Rename existing dest copy → "name.ext_1"
                if dst_file.exists():
                    alt = dst_file.parent / (dst_file.name + "_1")
                    if not alt.exists():
                        dst_file.rename(alt)
                phase3_moved += 1
                continue

            # "_" already taken → find next free _N
            n = 1
            while True:
                candidate = dst_file.parent / f"{dst_file.name}_{n}"
                if not candidate.exists():
                    break
                n += 1
            src_file.move(candidate)
            phase3_moved += 1

        # ── Cleanup empty dirs left in source ─────────────────────
        self._prune_empty_dirs(src_dir)

        # ── Refresh ranger tabs ───────────────────────────────────
        self.fm.thisdir.load_content()
        for tab_obj in self.fm.tabs.values():
            tab_obj.load_content()

        self.fm.notify(
            f"Done — moved {phase1_moved} unique, "
            f"removed {phase2_removed} identical, "
            f"suffixed {phase3_moved} conflicting."
        )

    # ── helpers ────────────────────────────────────────────────────

    def _next_tab_path(self):
        """
        Return the path of the *next* tab after the current one,
        wrapping around.  Tabs 1,2,5 with current=2 → returns tab 5's
        path; current=5 → returns tab 1's path.
        """
        tabs = self.fm.tabs
        current_tab = self.fm.current_tab
        sorted_keys = sorted(tabs.keys())

        if len(sorted_keys) < 2:
            self.fm.notify("No other tab open — open a second tab first.", bad=True)
            return None

        idx = sorted_keys.index(current_tab)
        next_key = sorted_keys[(idx + 1) % len(sorted_keys)]
        return tabs[next_key].path

    @staticmethod
    def _files_identical(a, b, bufsize=8192):
        """Byte-level comparison, equivalent to `cmp -s`."""
        try:
            if a.stat().st_size != b.stat().st_size:
                return False
        except OSError:
            return False
        with open(a, "rb") as fa, open(b, "rb") as fb:
            while True:
                chunk_a = fa.read(bufsize)
                chunk_b = fb.read(bufsize)
                if chunk_a != chunk_b:
                    return False
                if not chunk_a:
                    return True

    @staticmethod
    def _prune_empty_dirs(root):
        """Remove empty subdirectories bottom-up (leaves root itself)."""
        for dirpath, dirnames, filenames in os.walk(str(root), topdown=False):
            if dirpath == str(root):
                continue
            if not os.listdir(dirpath):
                os.rmdir(dirpath)
