"""vdguard: clip + symlink guards for cut / paste / :rename / :delete inside the VD roots.

fm.cut / fm.paste / :rename ask about clips + symlinks first and can re-point (U) or replace
(R) the symlinks once the files have really moved; every prompt is preceded by a list of the
links, also appended to RECOVERY_LOG.  :delete gets the same clip + symlink guards.

Paste/cut are NOT patched here: the guards are registered with pasteflow (see the end of the
file), which owns the single wrapper around Actions.paste* and the CopyLoader hand-off.
"""

from __future__ import annotations

import logging
import os
import re
import subprocess
import time
from collections.abc import Callable, Sequence
from os import path as fs
from typing import NamedTuple

from ranger.config.commands import delete as _default_delete
from ranger.config.commands import rename as _default_rename
from ranger.config.commands import trash as _default_trash
from ranger.ext.shell_escape import shell_quote

try:  # ranger imports plugins as `plugins.<name>` with the confdir on sys.path
    from plugins import pasteflow, rhooks
    from plugins import vdconf as C
    from plugins import vddangling as _dang
    from plugins import vdsym as _core
    from plugins.vdutil import (_brief, _dangling, _link_text, _norm,
                                _recovery, _safe_readlink, _swap_link,
                                replace_link)
except ImportError:  # fallback: the plugin files somewhere on PYTHONPATH
    import pasteflow
    import rhooks
    import vdconf as C
    import vddangling as _dang
    import vdsym as _core
    from vdutil import (_brief, _dangling, _link_text, _norm, _recovery,
                        _safe_readlink, _swap_link, replace_link)

_LOG = logging.getLogger("ranger.vdsym")

# Clip naming: "<stem>_00m33s6", "<stem>_v32", "<stem>_06m44s7_prev29267", any extension.
_TOKEN = r"(?:\d+m\d+s\d+|v\d+|prev\d+)"


_CLIP_SUFFIX = _TOKEN + "(?:_" + _TOKEN + ")*"


def _leave_link_text(old: str, new: str) -> str:
    """Use a relative link within one VD root.  Do not make cross-root links relative."""
    new = _norm(new)
    if _core._vd_root(old) == _core._vd_root(new) and _core._vd_root(new) is not None:
        return fs.relpath(new, fs.realpath(fs.dirname(old)))
    return new


class _Stage(NamedTuple):
    hit: _core._Hit
    old: str
    predicted: str
    backup: str
    dest: str | None
    text: str
    kind: str  # U, R, or K (R collision kept under its old name)


def find_clips(paths: Sequence[str]) -> list[str]:
    """Siblings named '<stem>_<clip tokens>[.ext]' that are not themselves in `paths`."""
    stems: dict[str, list[str]] = {}
    for path in paths:
        stems.setdefault(fs.dirname(path), []).append(fs.splitext(fs.basename(path))[0])
    selected = set(paths)
    found: list[str] = []
    for directory, group in stems.items():
        pattern = re.compile(
            f"(?:{'|'.join(map(re.escape, group))})_{_CLIP_SUFFIX}(?:\\..*)?", re.S
        )
        try:
            with os.scandir(directory) as it:
                found.extend(
                    e.path
                    for e in it
                    if e.path not in selected and pattern.fullmatch(e.name)
                )
        except OSError:
            continue
    return sorted(found)


# --------------------------------------------------------------------------- #
# guarded moves: shared by fm.cut / fm.paste / :rename
# --------------------------------------------------------------------------- #


class _MoveJob:
    """Re-point (U) or replace (R) symlinks once the files they led to have really moved.

    Hits are computed *before* the move (a moved directory can no longer be walked), applied
    after it, and only for files that are gone from `old` and found at their new place, so a
    cancelled or failed move leaves everything as it was. The new place is the predicted
    path, verified (and if needed searched in the destination dir) by inode.
    Links in DASHBOARD_ROOT are always re-pointed in place.
    """

    def __init__(
        self, fm, moves: dict[str, str], policy: dict[str, str], hits: list[_core._Hit]
    ) -> None:
        self.fm, self.moves, self.policy, self.hits = fm, moves, policy, hits
        self.by_subject = {_norm(old): old for old in moves}
        self.ids: dict[str, tuple[int, int]] = {}
        for old in moves:
            try:
                st = os.lstat(old)
                self.ids[old] = (st.st_dev, st.st_ino)
            except OSError:
                pass
        self.stages: list[_Stage] = []
        self.staged = False
        self.tx = f".vdsym-old-{os.getpid()}-{time.time_ns()}"
        self.done = False

    def _locate(self, old: str, predicted: str) -> str | None:
        if fs.lexists(old):
            return None  # still there: not moved (cancelled, failed, copy not finished)
        ident = self.ids.get(old)
        if fs.lexists(predicted):
            if ident is None:
                return predicted
            st = os.lstat(predicted)
            if (st.st_dev, st.st_ino) == ident or st.st_dev != ident[0]:
                return predicted  # same inode, or copied across filesystems (inode can't tell)
        if (
            ident
        ):  # predicted name was wrong (name clash in the batch, race): find by inode
            try:
                with os.scandir(fs.dirname(predicted)) as it:
                    for entry in it:
                        st = entry.stat(follow_symlinks=False)
                        if (st.st_dev, st.st_ino) == ident:
                            return entry.path
            except OSError:
                pass
        return None

    @staticmethod
    def _is_dashboard(link: str) -> bool:
        return fs.abspath(link).startswith(fs.abspath(C.DASHBOARD_ROOT) + os.sep)

    def stage(self) -> bool:
        """Keep every old link under a recoverable name before making replacement links."""
        work: list[tuple[_core._Hit, str, str, str]] = []
        for hit in self.hits:
            old = self.by_subject.get(hit.subject)
            predicted = self.moves.get(old) if old else None
            if predicted is None:
                continue
            mode = "UA" if self._is_dashboard(hit.link) else self.policy.get(old)
            if mode == "U" and not hit.direct:
                continue
            if mode not in ("U", "UA", "R"):
                continue
            work.append((hit, old, predicted, mode))
        if not work:
            return True
        work.sort(
            key=lambda item: (
                fs.basename(item[0].link) != fs.basename(_norm(item[2]) + item[0].rest)
            )
        )
        sources = {hit.link for hit, _, _, _ in work}
        owners: set[str] = set()
        stages: list[_Stage] = []
        for hit, old, predicted, mode in work:
            target = _norm(predicted) + hit.rest
            dest = (
                hit.link
                if mode in ("U", "UA")
                else fs.join(fs.dirname(hit.link), fs.basename(target))
            )
            kind = "U" if mode == "UA" else mode
            if dest in owners:
                dest = None
            elif dest not in sources and fs.lexists(dest):
                if fs.islink(dest) and fs.realpath(dest) == fs.realpath(target):
                    dest = None
                elif mode == "R":
                    dest, kind = hit.link, "K"
                else:
                    return False
            if dest:
                owners.add(dest)
            stages.append(
                _Stage(
                    hit,
                    old,
                    predicted,
                    hit.link + self.tx,
                    dest,
                    _link_text(hit.link, old, predicted, hit.rest),
                    kind,
                )
            )
        try:
            for stage in stages:
                if not fs.islink(stage.hit.link) or fs.lexists(stage.backup):
                    raise OSError(f"cannot stage {stage.hit.link}")
                os.replace(stage.hit.link, stage.backup)
            for stage in stages:
                if stage.dest:
                    _swap_link(stage.hit.link, stage.text, stage.dest)
        except OSError as error:
            self.stages = stages
            self._rollback()
            self.fm.notify(f"could not stage symlinks: {error}", bad=True)
            return False
        self.stages = stages
        self.staged = True
        _recovery(
            f"staged {len(stages)} symlink(s)",
            [f"{stage.backup} -> {stage.hit.link}" for stage in stages],
        )
        return True

    def _rollback(self, stages: Sequence[_Stage] | None = None) -> list[str]:
        """Remove staged links then put surviving old links back under their original names."""
        problems: list[str] = []
        for stage in reversed(self.stages if stages is None else stages):
            try:
                if (
                    stage.dest
                    and fs.islink(stage.dest)
                    and _safe_readlink(stage.dest) == stage.text
                ):
                    os.unlink(stage.dest)
                if fs.lexists(stage.backup) and not fs.lexists(stage.hit.link):
                    os.replace(stage.backup, stage.hit.link)
            except OSError as error:
                problems.append(f"{stage.hit.link}: {error}")
        return problems

    def _finish_staged(self, located: dict[str, str | None]) -> None:
        problems: list[str] = []
        committed: list[_Stage] = []
        for stage in self.stages:
            new = located.get(stage.old)
            if new is None:
                continue
            try:
                if stage.dest:
                    text = _link_text(stage.hit.link, stage.old, new, stage.hit.rest)
                    _swap_link(stage.hit.link, text, stage.dest)
                if fs.lexists(stage.backup):
                    os.unlink(stage.backup)
                committed.append(stage)
            except OSError as error:
                problems.append(f"{stage.hit.link}: {error}")
        failed = [stage for stage in self.stages if stage not in committed]
        problems += self._rollback(failed)
        updated = sum(stage.kind == "U" for stage in committed)
        replaced = sum(stage.kind == "R" for stage in committed)
        kept = sum(stage.kind == "K" for stage in committed)
        if committed or problems:
            self.fm.notify(
                f"symlinks: {updated} updated, {replaced} replaced"
                + (f", {kept} re-pointed in place (name taken)" if kept else "")
                + (f", {len(problems)} problem(s)" if problems else ""),
                bad=bool(problems),
            )

    def finish(self) -> None:
        if self.done:
            return
        self.done = True
        located = {
            old: self._locate(old, predicted) for old, predicted in self.moves.items()
        }
        if self.staged:
            self._finish_staged(located)
            _core._cache.touch(
                path
                for stage in self.stages
                for path in (stage.hit.link, stage.backup, stage.dest)
                if path
            )
            _dang._arm()
            return
        problems: list[str] = []
        work: list[tuple[_core._Hit, str, str]] = []
        for hit in self.hits:
            old = self.by_subject.get(hit.subject)
            if old is None:
                continue
            new = located.get(old)
            if new is None:
                note = f"not moved: {old} (links to it left alone)"
                if note not in problems:
                    problems.append(note)
                continue
            work.append((hit, old, new))
        # a link that already has the final name goes first, the others then find it in place
        # and are simply removed (otherwise they would collide with it)
        work.sort(
            key=lambda w: fs.basename(w[0].link) != fs.basename(_norm(w[2]) + w[0].rest)
        )
        touched: set[str] = set()
        updated = replaced = kept = 0
        for hit, old, new in work:
            mode = "UA" if self._is_dashboard(hit.link) else self.policy.get(old)
            try:
                text = _link_text(hit.link, old, new, hit.rest)
                if mode == "UA" or (mode == "U" and hit.direct):
                    _swap_link(hit.link, text)
                    updated += 1
                elif mode == "R":
                    error = replace_link(hit.link, text, _norm(new) + hit.rest)
                    if error and error.startswith("Collision"):
                        # a foreign file owns the wanted name: never overwrite it, but don't
                        # leave the old link dangling either - re-point it under its old name
                        _swap_link(hit.link, text)
                        kept += 1
                        problems.append(f"{error} - kept {hit.link} (re-pointed)")
                    elif error:
                        problems.append(f"{hit.link}: {error}")
                        continue
                    else:
                        replaced += 1
                else:
                    continue
            except OSError as error:
                problems.append(f"{hit.link}: {error}")
                continue
            touched.add(hit.link)
            touched.add(fs.join(fs.dirname(hit.link), fs.basename(new)))
        if touched:
            _core._cache.touch(touched)
        _dang._arm()
        for old, new in located.items():
            _core._cache.visited.add(fs.dirname(old))
            if new:
                _core._cache.visited.add(fs.dirname(new))
        _recovery(
            f"done updated={updated} replaced={replaced} kept={kept} problems={len(problems)}",
            problems,
        )
        if updated or replaced or kept or problems:
            self.fm.notify(
                f"symlinks: {updated} updated, {replaced} replaced"
                + (f", {kept} re-pointed in place (name taken)" if kept else "")
                + (
                    f", {len(problems)} problem(s) (see {C.RECOVERY_LOG})"
                    if problems
                    else ""
                ),
                bad=bool(problems),
            )


class _DanglingPasteJob:
    """Hold dangling destination links aside while non-append overwrite copies replace them."""

    def __init__(self, fm, paths: Sequence[str]) -> None:
        self.fm = fm
        suffix = f".vdsym-dangling-{os.getpid()}-{time.time_ns()}"
        self.stages = [(path, path + suffix) for path in paths]
        self.done = False

    def stage(self) -> bool:
        try:
            for path, backup in self.stages:
                if not fs.islink(path) or not _dangling(path) or fs.lexists(backup):
                    raise OSError(f"cannot stage dangling symlink {path}")
                os.replace(path, backup)
        except OSError as error:
            self.finish()
            self.fm.notify(f"could not stage dangling symlink: {error}", bad=True)
            return False
        return True

    def finish(self) -> None:
        if self.done:
            return
        self.done = True
        problems: list[str] = []
        for path, backup in self.stages:
            try:
                if fs.lexists(path):
                    if fs.lexists(backup):
                        os.unlink(backup)
                elif fs.lexists(backup):
                    os.replace(backup, path)
            except OSError as error:
                problems.append(f"{path}: {error}")
        _core._cache.touch(path for stage in self.stages for path in stage)
        if problems:
            self.fm.notify(
                f"{len(problems)} dangling symlink replacement problem(s)", bad=True
            )


class _LeaveLinkJob:
    """After a cut succeeds, put a link at each vacated source path."""

    def __init__(self, fm, moves: dict[str, str]) -> None:
        self.fm = fm
        self.moves = moves
        self.ids: dict[str, tuple[int, int]] = {}
        for old in moves:
            try:
                st = os.lstat(old)
                self.ids[old] = (st.st_dev, st.st_ino)
            except OSError:
                pass
        self.done = False

    def finish(self) -> None:
        if self.done:
            return
        self.done = True
        left = problems = 0
        for old, predicted in self.moves.items():
            if fs.lexists(old):
                continue
            new = _MoveJob._locate(self, old, predicted)
            if new is None:
                continue
            try:
                os.symlink(_leave_link_text(old, new), old)
                left += 1
            except OSError:
                problems += 1
        _core._cache.touch(path for move in self.moves.items() for path in move)
        if left or problems:
            self.fm.notify(
                f"source links: {left} left"
                + (f", {problems} problem(s)" if problems else ""),
                bad=bool(problems),
            )


def _print_links(fm, op: str, hits: list[_core._Hit]) -> None:
    if not C.PRINT_BEFORE_PROMPT or not hits:
        return
    lines = [f"{op}: {len(hits)} symlink(s) lead here"]
    lines += [f"{hit.link} -> {_safe_readlink(hit.link) or '?'}" for hit in hits]
    fm.execute_command("printf '%s\\n' " + shell_quote("\n".join(lines)), flags="-w")


def _guard_move(
    fm,
    paths: Sequence[str],
    op: str,
    done: Callable[[str], None],
    cancel: Callable[[], None],
) -> None:
    """Ask about clips / symlinks before `op` (cut, move, rename) touches `paths`.

    done(policy) with policy "" (nothing found), "y" (go, leave links), "U" (update) or
    "R" (replace); cancel() otherwise. Enter and Esc both answer "cancel".
    """
    ask = fm.ui.console.ask
    _dang._arm()
    clips = find_clips(paths)
    subjects = [path for path in paths if _core._under_roots(path)]
    hits = _core.find_hits(subjects, C.LOCK_WAIT) if subjects else []
    if hits is None:
        ask(
            f"link scan unavailable (cache is warming) -- {op} anyway? (y / C=cancel)",
            lambda ans: done("y") if ans in ("y", "Y") else cancel(),
            ("c", "C", "y", "Y"),
        )
        return
    hits = _core._drop_moving(hits, paths)
    if not hits and not clips:
        return done("")
    _recovery(
        op,
        [f"path {p}" for p in paths]
        + [f"link {h.link} -> {_safe_readlink(h.link)}" for h in hits]
        + [f"clip {c}" for c in clips],
    )
    _print_links(fm, op, hits)
    parts = []
    if hits:
        parts.append(f"{len(hits)} symlink(s): {_brief(h.link for h in hits)}")
    if clips:
        parts.append(f"{len(clips)} clip(s)")
    if hits:
        text = (
            " + ".join(parts)
            + f" -- {op}? (y=leave / U=update / R=replace / n=dashboard / C=cancel)"
        )
        choices: tuple[str, ...] = ("c", "C", "y", "Y", "n", "N", "U", "R")
    else:
        text = parts[0] + f" -- {op} anyway? (y / C=cancel)"
        choices = ("c", "C", "y", "Y")

    def answer(ans: str) -> None:
        if ans in ("U", "R"):
            done(ans)
        elif ans in ("y", "Y"):
            _dang._acknowledge(hit.link for hit in hits)
            done("y")
        else:
            if ans in ("n", "N"):
                dest = fs.join(C.DASHBOARD_ROOT, fs.basename(paths[0]))
                _core.make_dashboard(fm, [hit.link for hit in hits], dest)
            cancel()

    ask(text, answer, choices)


def _same_link_target(source: str, dest: str) -> bool:
    """Both paths are links resolving to the same destination, including dangling links."""
    return (
        fs.islink(source)
        and fs.islink(dest)
        and fs.realpath(source) == fs.realpath(dest)
    )


def _link_targets_path(link: str, path: str) -> bool:
    return fs.islink(link) and fs.realpath(link) == fs.realpath(path)


def _duplicate_link_note(count: int) -> str:
    return (
        "symlink with same target already exists"
        if count == 1
        else f"{count} symlinks with same target already exist"
    )


# --------------------------------------------------------------------------- #
# :delete
# --------------------------------------------------------------------------- #


class _FmProxy:
    """fm as seen by one :delete instance: delete() redirected, rest passed through."""

    def __init__(self, fm, delete) -> None:
        self._fm = fm
        self.delete = delete

    def __getattr__(self, name):
        return getattr(self._fm, name)


# OR: map dD eval fm.set_clipboard(fm.thisfile.basename.encode('utf-8')); cmd('delete')
class _GuardedRemoval:
    """Shared clip/link guards and clipboard behavior for delete and trash."""

    def _guarded_remove(self, files, action: str, perform) -> None:
        fm = getattr(self, "_real_fm", self.fm)
        if files is None:
            files = [f.path for f in fm.thistab.get_selection()]
        paths = [
            fs.abspath(
                item.path if hasattr(item, "path") else fs.join(fm.thisdir.path, item)
            )
            for item in files
        ]
        clips = find_clips(paths)
        _dang._arm()
        subjects = [path for path in paths if _core._under_roots(path)]
        hits = _core.find_hits(subjects, C.LOCK_WAIT) if subjects else []
        if hits is None:
            items = [f"clip {path}" for path in clips]
            items += [f"item {path}" for path in paths]
            names = ", ".join(fs.basename(path) for path in clips)
            prompt = f"link scan unavailable (cache warming) -- {action} anyway? ({len(clips)} clip(s): {names}; y / l=list / C=cancel)"
            compact_prompt = f"link scan unavailable (cache warming) -- {action} anyway? ({len(clips)} clip(s); y / l=list / C=cancel)"
            return self._ask_remove(
                fm,
                prompt,
                compact_prompt,
                ("c", "C", "y", "Y"),
                items,
                lambda ans: (
                    ans in ("y", "Y")
                    and self._copy_and_remove(fm, files, paths, perform)
                ),
            )
        hits = _core._drop_moving(hits, paths)
        links = [hit.link for hit in hits]
        if not clips and not links:
            return self._copy_and_remove(fm, files, paths, perform)

        _recovery(
            action,
            [f"path {path}" for path in paths]
            + [f"link {hit.link} -> {_safe_readlink(hit.link)}" for hit in hits]
            + [f"clip {clip}" for clip in clips],
        )
        _print_links(fm, action, hits)
        details = []
        compact_details = []
        if clips:
            details.append(
                f"{len(clips)} clip(s): {', '.join(fs.basename(path) for path in clips)}"
            )
            compact_details.append(f"{len(clips)} clip(s)")
        if links:
            details.append(
                f"{len(links)} symlink(s): {', '.join(fs.basename(path) for path in links)}"
            )
            compact_details.append(f"{len(links)} symlink(s)")
        suffix = f" -- {action}? (y / n=dashboard / l=list / C=cancel)"
        prompt = " + ".join(details) + suffix
        compact_prompt = " + ".join(compact_details) + suffix
        items = [f"clip {path}" for path in clips]
        items += [
            f"symlink {link} -> {_safe_readlink(link) or '?'}" for link in links
        ]

        def answer(ans: str) -> None:
            if ans in ("y", "Y"):
                _dang._acknowledge(links)
                self._copy_and_remove(fm, files, paths, perform)
            elif ans in ("n", "N") and links:
                _core.make_dashboard(
                    fm, links, fs.join(C.DASHBOARD_ROOT, fs.basename(paths[0]))
                )

        self._ask_remove(
            fm, prompt, compact_prompt, ("c", "C", "y", "Y", "n", "N"), items,
            answer,
        )

    def _copy_and_remove(self, fm, files, paths, perform) -> None:
        if self._copy_names([fs.basename(path) for path in paths]):
            perform(files)
        else:
            fm.notify("Could not copy file name to clipboard", bad=True)

    @staticmethod
    def _ask_remove(fm, full_text, compact_text, choices, items, callback) -> None:
        console = fm.ui.console
        text = full_text if len(full_text) <= max(20, getattr(console, "wid", 80)) else compact_text
        choices = tuple(choices)
        if items and "l" not in choices:
            choices += ("l", "L")

        def answer(value):
            if value in ("l", "L"):
                listing = "\n".join(items)
                command = "printf '%s\\n' " + shell_quote(listing)
                fm.execute_command(command, flags="-w")
                return _GuardedRemoval._ask_remove(
                    fm, full_text, compact_text, choices, items, callback
                )
            callback(value)

        console.ask(text, answer, choices)

    @staticmethod
    def _copy_names(names: Sequence[str]) -> bool:
        try:
            process = subprocess.run(
                ["xci"],
                input="\n".join(names),
                text=True,
                capture_output=True,
                check=False,
            )
        except OSError:
            return False
        return process.returncode == 0


class delete(_GuardedRemoval, _default_delete):
    """:delete

    Copy selected file names to the clipboard before deleting them.
    Deletion is skipped when clipboard copy fails.
    Asks first when the files have sibling clips or symlinks leading to them (files, symlinks
    and directories inside the VD roots). Enter/Esc on the prompts always cancel.
    """

    def execute(self) -> None:
        self._real_fm = self.fm
        self.fm = _FmProxy(self._real_fm, self._guarded_delete)  # this command only
        super().execute()

    def _guarded_delete(self, files: Sequence[str] | None = None) -> None:
        self._guarded_remove(files, "delete", self._real_fm.delete)


class trash(_GuardedRemoval, _default_trash):
    """:trash keeps Ranger's confirmation and Rifle execution, with VD guards.

    Trashing moves paths to a backend-chosen destination, so symlinks cannot be re-pointed
    predictably. Ask before breaking clips/back-references; dashboard option preserves links.
    """

    def _trash_files_catch_arg_list_error(self, files) -> None:
        self._guarded_remove(
            files,
            "trash",
            lambda selected: super(trash, self)._trash_files_catch_arg_list_error(
                selected
            ),
        )


class rename(_default_rename):
    """:rename <newname>

    Asks first when clips or symlinks depend on the old name (see _guard_move).
    """

    def execute(self) -> None:
        fm, cursor, new_name = self.fm, self.fm.thisfile, self.rest(1)
        if (
            not new_name
            or not cursor
            or new_name == cursor.relative_path
            or fs.lexists(new_name)
        ):
            return super().execute()  # stock code reports these itself
        old = fs.abspath(cursor.path)
        new = fs.abspath(fs.join(fm.thisdir.path, new_name))

        def done(policy: str) -> None:
            job = None
            if policy in ("U", "R"):
                hits = _core._drop_moving(
                    _core.find_hits([old], C.LOCK_WAIT, True) or [], [old]
                )
                _recovery("rename", [f"{old} -> {new}"])
                if hits:
                    job = _MoveJob(fm, {old: new}, {old: policy}, hits)
                    if not job.stage():
                        return
            super(rename, self).execute()
            if job:
                job.finish()

        _guard_move(fm, [old], "rename", done, lambda: None)
        return None


# --------------------------------------------------------------------------- #
# cut / paste guards, registered with pasteflow (the ONE wrapper around Actions.paste*)
#
# Priorities: link filtering 10 (cheap, may cancel) ... staging guards 90, i.e. LAST: they
# rename links aside, so no later guard may cancel the paste after that (it would leave the
# staged names behind). Foreign guards at the default 50 therefore run before ours.
# --------------------------------------------------------------------------- #

# path -> "" | y | U | R : the answer given at :cut time (what to do with the links on paste)
_POLICY: dict[str, str] = rhooks.shared("vdguard.policy", dict)


def _on_reset(fm) -> None:
    _POLICY.clear()  # :copy (set) / :uncut / :cut (calls :copy) start a fresh buffer


def _on_cut(fm, paths) -> None:
    fresh = [path for path in paths if path not in _POLICY]
    if not fresh:
        return

    def done(policy: str) -> None:
        for path in fresh:
            _POLICY[path] = policy

    def cancel() -> None:
        pasteflow.unmark(fm, fresh)

    _guard_move(fm, fresh, "cut", done, cancel)


def _guard_links(p, proceed) -> None:
    """copy / symlink: leave_symlink needs a cut; entries whose link already exists at dest
    are skipped (noted), nothing left -> cancel."""
    if p.opts.get("leave_symlink") and p.kind != "move":
        p.fm.notify("source-link paste requires cut", bad=True)
        return
    if p.kind not in ("copy", "symlink") or not p.entries or not fs.isdir(p.dest):
        return proceed()
    if p.kind == "copy":
        same = _same_link_target
    else:  # symlink: the link at dest already points at this very path
        same = lambda path, dest: _link_targets_path(dest, path)  # noqa: E731
    duplicates = [
        path for path in p.paths if same(path, fs.join(p.dest, fs.basename(path)))
    ]
    if duplicates:
        p.fm.notify(_duplicate_link_note(len(duplicates)))
        p.drop(duplicates)
        if not p.entries:
            return
    proceed()


def _guard_dangling(p, proceed) -> None:
    """overwrite-copy: hold dangling destination links aside while ranger replaces them."""
    if (
        p.kind != "copy"
        or not p.overwrite
        or p.call.get("append")
        or not p.entries
        or not fs.isdir(p.dest)
    ):
        return proceed()
    dangling = [
        fs.join(p.dest, fs.basename(path))
        for path in p.paths
        if fs.islink(fs.join(p.dest, fs.basename(path)))
        and _dangling(fs.join(p.dest, fs.basename(path)))
    ]
    if dangling:
        job = _DanglingPasteJob(p.fm, dangling)
        if not job.stage():
            return
        p.after(lambda _p: job.finish())
    proceed()


def _guard_moves(p, proceed) -> None:
    """cut-paste: ask about clips / symlinks (unless answered at :cut time), then stage the
    link updates; they are applied when the files have really moved (p.after)."""
    if p.kind != "move" or not p.entries:
        return proceed()
    fm, paths, target = p.fm, p.paths, p.dest

    def go() -> None:
        wanted = {path: _POLICY.pop(path, "") for path in paths}
        active = {path: pol for path, pol in wanted.items() if pol in ("U", "R")}
        job = leave_job = None
        moves: dict[str, str] = {}
        if p.opts.get("leave_symlink") and fs.isdir(target):
            moves = pasteflow.predict_moves(
                paths, target, p.overwrite, p.make_safe_path
            )
            leave_job = _LeaveLinkJob(fm, moves)
        if active and fs.isdir(target):
            moves = pasteflow.predict_moves(
                list(active), target, p.overwrite, p.make_safe_path
            )
            hits = _core._drop_moving(
                _core.find_hits(list(moves), C.LOCK_WAIT, True) or [], paths
            )
            _recovery("paste", [f"{old} -> {new}" for old, new in moves.items()])
            if hits and moves:
                job = _MoveJob(fm, moves, active, hits)
                if not job.stage():
                    return
        if job:
            p.after(lambda _p: job.finish())
        if leave_job:  # after the move job, as the old _JobGroup(job, leave_job) did
            p.after(lambda _p: leave_job.finish())
        proceed()

    fresh = [path for path in paths if path not in _POLICY]
    if not fresh:
        return go()

    def done(policy: str) -> None:
        for path in fresh:
            _POLICY[path] = policy
        go()

    _guard_move(fm, fresh, "move", done, lambda: None)


pasteflow.on_reset("vdguard", _on_reset)
pasteflow.on_cut("vdguard", _on_cut)
pasteflow.guard("vdguard.links", _guard_links, 10)
pasteflow.guard("vdguard.dangling", _guard_dangling, 90)
pasteflow.guard("vdguard.moves", _guard_moves, 90)

## ALT: vdsym patched Actions.copy/uncut/cut/paste/paste_symlink + CopyLoader itself, handing
##      the job to the loader through a global (_STATE.job).
##      benefit: one self-contained file, no pasteflow dependency;
##      cost: clashed with any other paste plugin, no completion hook for a cursor jump,
##      the duplicate-link branch skipped the dangling-overwrite staging (it returned early).
##      Verbatim original below.
# class _JobGroup:
#     def __init__(self, *jobs) -> None:
#         self.jobs = [job for job in jobs if job is not None]
#
#     def finish(self) -> None:
#         for job in self.jobs:
#             job.finish()
# def _safe_like(dst: str, taken: set[str]) -> str:
#     """ranger's get_safe_path(), also treating names taken earlier in the same batch as existing."""
#
#     def exists(path: str) -> bool:
#         return fs.exists(path) or path in taken
#
#     if not exists(dst):
#         return dst
#     if not dst.endswith("_"):
#         dst += "_"
#         if not exists(dst):
#             return dst
#     n = 0
#     while exists(dst + str(n)):
#         n += 1
#     return dst + str(n)
# def _predict_moves(
#     paths: Sequence[str], dest: str, overwrite: bool, make_safe_path
# ) -> dict[str, str]:
#     """Where ranger's mover will put each path (same rule as shutil_generatorized.move)."""
#     moves: dict[str, str] = {}
#     taken: set[str] = set()
#     for old in paths:
#         real = fs.join(dest, fs.basename(old))
#         if overwrite:
#             new = real
#         elif make_safe_path is get_safe_path:
#             new = _safe_like(real, taken)
#         else:
#             new = make_safe_path(real)
#             if new in taken:
#                 _LOG.warning("cannot predict destination of %s", old)
#                 continue
#         taken.add(new)
#         moves[old] = new
#     return moves
# # --------------------------------------------------------------------------- #
# # patches of ranger internals (idempotent, re-exec safe, skipped if ranger differs)
# # --------------------------------------------------------------------------- #
#
# _STATE = types.SimpleNamespace(job=None, policy={})  # policy: path -> "" | y | U | R
# def _patch(owner, name: str, make) -> None:
#     originals = sys.modules["_vdsym_shared"].orig
#     original = originals.setdefault((owner, name), getattr(owner, name))
#     setattr(owner, name, make(original))
# def _make_copy(orig):
#     def copy(self, mode="set", narg=None, dirarg=None):
#         if mode == "set":
#             _STATE.policy.clear()
#         return orig(self, mode=mode, narg=narg, dirarg=dirarg)
#
#     return copy
# def _make_uncut(orig):
#     def uncut(self):
#         _STATE.policy.clear()
#         return orig(self)
#
#     return uncut
# def _make_cut(orig):
#     def cut(self, mode="set", narg=None, dirarg=None):
#         orig(
#             self, mode=mode, narg=narg, dirarg=dirarg
#         )  # its self.copy() resets the policy
#         if not self.do_cut:
#             return
#         fresh = [f.path for f in self.copy_buffer if f.path not in _STATE.policy]
#         if not fresh:
#             return
#
#         def done(policy: str) -> None:
#             for path in fresh:
#                 _STATE.policy[path] = policy
#
#         def cancel() -> None:
#             gone = set(fresh)
#             self.copy_buffer = {f for f in self.copy_buffer if f.path not in gone}
#             self.do_cut = bool(self.copy_buffer)
#             self.ui.browser.main_column.request_redraw()
#
#         _guard_move(self, fresh, "cut", done, cancel)
#
#     return cut
# def _make_paste(orig):
#     def paste(
#         self,
#         overwrite=False,
#         append=False,
#         dest=None,
#         make_safe_path=get_safe_path,
#         leave_symlink=False,
#     ):
#         target = self.thistab.path if dest is None else dest
#         if leave_symlink and not self.do_cut:
#             self.notify("source-link paste requires cut", bad=True)
#             return None
#         if not self.do_cut and self.copy_buffer and fs.isdir(target):
#             duplicates = [
#                 entry
#                 for entry in self.copy_buffer
#                 if _same_link_target(entry.path, fs.join(target, entry.basename))
#             ]
#             if duplicates:
#                 self.notify(_duplicate_link_note(len(duplicates)))
#                 remaining = set(self.copy_buffer) - set(duplicates)
#                 if not remaining:
#                     return None
#                 saved, self.copy_buffer = self.copy_buffer, remaining
#                 try:
#                     return orig(
#                         self,
#                         overwrite=overwrite,
#                         append=append,
#                         dest=dest,
#                         make_safe_path=make_safe_path,
#                     )
#                 finally:
#                     self.copy_buffer = saved
#         if not self.do_cut:
#             if overwrite and not append and self.copy_buffer and fs.isdir(target):
#                 dangling = [
#                     fs.join(target, entry.basename)
#                     for entry in self.copy_buffer
#                     if fs.islink(fs.join(target, entry.basename))
#                     and _dangling(fs.join(target, entry.basename))
#                 ]
#                 if dangling:
#                     job = _DanglingPasteJob(self, dangling)
#                     if not job.stage():
#                         return None
#                     _STATE.job = job
#                     try:
#                         return orig(
#                             self,
#                             overwrite=overwrite,
#                             append=append,
#                             dest=dest,
#                             make_safe_path=make_safe_path,
#                         )
#                     finally:
#                         _STATE.job = None
#             return orig(
#                 self,
#                 overwrite=overwrite,
#                 append=append,
#                 dest=dest,
#                 make_safe_path=make_safe_path,
#             )
#         if not self.copy_buffer:
#             return orig(
#                 self,
#                 overwrite=overwrite,
#                 append=append,
#                 dest=dest,
#                 make_safe_path=make_safe_path,
#             )
#         paths = [f.path for f in self.copy_buffer]
#
#         def go() -> None:
#             wanted = {p: _STATE.policy.pop(p, "") for p in paths}
#             active = {p: pol for p, pol in wanted.items() if pol in ("U", "R")}
#             job = None
#             leave_job = None
#             moves = {}
#             if leave_symlink and fs.isdir(target):
#                 moves = _predict_moves(paths, target, overwrite, make_safe_path)
#                 leave_job = _LeaveLinkJob(self, moves)
#             if active and fs.isdir(target):
#                 moves = _predict_moves(list(active), target, overwrite, make_safe_path)
#                 hits = _drop_moving(
#                     find_hits(list(moves), LOCK_WAIT, True) or [], paths
#                 )
#                 _recovery("paste", [f"{old} -> {new}" for old, new in moves.items()])
#                 if hits and moves:
#                     job = _MoveJob(self, moves, active, hits)
#                     if not job.stage():
#                         return
#             _STATE.job = _JobGroup(job, leave_job) if leave_job else job
#             try:
#                 orig(
#                     self,
#                     overwrite=overwrite,
#                     append=append,
#                     dest=target,
#                     make_safe_path=make_safe_path,
#                 )
#             finally:
#                 _STATE.job = None
#
#         fresh = [p for p in paths if p not in _STATE.policy]
#         if not fresh:
#             return go()
#
#         def done(policy: str) -> None:
#             for path in fresh:
#                 _STATE.policy[path] = policy
#             go()
#
#         _guard_move(self, fresh, "move", done, lambda: None)
#         return None
#
#     return paste
# def _make_paste_symlink(orig):
#     def paste_symlink(self, relative=False, make_safe_path=get_safe_path):
#         target = self.thisdir.path
#         duplicates = [
#             entry
#             for entry in self.copy_buffer
#             if _link_targets_path(fs.join(target, entry.basename), entry.path)
#         ]
#         if not duplicates:
#             return orig(self, relative=relative, make_safe_path=make_safe_path)
#         self.notify(_duplicate_link_note(len(duplicates)))
#         remaining = set(self.copy_buffer) - set(duplicates)
#         if not remaining:
#             return None
#         saved, self.copy_buffer = self.copy_buffer, remaining
#         try:
#             return orig(self, relative=relative, make_safe_path=make_safe_path)
#         finally:
#             self.copy_buffer = saved
#
#     return paste_symlink
# def _make_work(orig):
#     def work(self, *args, **kwargs):
#         result = orig(self, *args, **kwargs)
#         _tick()
#         return result
#
#     return work
# def _make_loader_init(orig):
#     def __init__(self, *args, **kwargs):
#         self._vdsym_job = _STATE.job
#         orig(self, *args, **kwargs)
#
#     return __init__
# def _make_loader_generate(orig):
#     def generate(self):
#         job = getattr(self, "_vdsym_job", None)
#         try:
#             yield from orig(self)
#         finally:  # completion, error or cancel: reconcile what really moved
#             if job is not None:
#                 job.finish()
#
#     return generate
# def _install() -> None:
#     try:
#         import ranger
#         import ranger.api
#         from ranger.core.actions import Actions
#         from ranger.core.loader import CopyLoader, Loader
#
#         for owner, name, make in (
#             (Actions, "copy", _make_copy),
#             (Actions, "uncut", _make_uncut),
#             (Actions, "cut", _make_cut),
#             (Actions, "paste", _make_paste),
#             (Actions, "paste_symlink", _make_paste_symlink),
#             (CopyLoader, "__init__", _make_loader_init),
#             (CopyLoader, "generate", _make_loader_generate),
#             (Loader, "work", _make_work),
#         ):
#             _patch(owner, name, make)
#         _bind_cd(getattr(ranger, "fm", None))
#         if not getattr(ranger.api.hook_init, "_vdsym", False):
#             previous = ranger.api.hook_init
#
#             def hook_init(fm):
#                 _bind_cd(fm)
#                 return previous(fm)
#
#             hook_init._vdsym = True  # type: ignore[attr-defined]
#             ranger.api.hook_init = hook_init
#     except Exception:
#         _LOG.exception("vdsym: move guards / cd signal not installed")
