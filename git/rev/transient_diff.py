#!/usr/bin/env python3
"""Show feature-branch additions that disappeared before the branch tip."""
from __future__ import annotations

import argparse
import collections
import dataclasses
import difflib
import os
import re
import subprocess
import sys
from pathlib import Path

type DiffHunk = tuple[int, int, int, int]


@dataclasses.dataclass(frozen=True)
class Origin:
    commit: str
    index: int
    subject: str


@dataclasses.dataclass(frozen=True)
class Lineage:
    origin: Origin
    birth_path: str
    birth_line_index: int
    birth_source_lines: tuple[str, ...]
    birth_changed_indexes: frozenset[int]
    birth_hunks: tuple[DiffHunk, ...]
    birth_file_added: bool


@dataclasses.dataclass
class LostLine:
    lineage: Lineage
    removed_by: str
    removed_index: int
    removed_subject: str
    path: str
    text: str
    line_index: int
    source_lines: tuple[str, ...]
    removal_changed_indexes: frozenset[int]
    removal_hunks: tuple[DiffHunk, ...]
    removal_file_deleted: bool


@dataclasses.dataclass(frozen=True)
class RemovedLine:
    lineage: Lineage | None
    path: str
    line_index: int
    text: str
    source_lines: tuple[str, ...]
    changed_indexes: frozenset[int]
    hunks: tuple[DiffHunk, ...]
    file_deleted: bool


@dataclasses.dataclass
class AddedLine:
    path: str
    line_index: int
    identities: list[Lineage | None]
    source_lines: tuple[str, ...]
    changed_indexes: frozenset[int]
    hunks: tuple[DiffHunk, ...]
    file_added: bool


@dataclasses.dataclass(frozen=True)
class BaselineTombstone:
    line_index: int
    text: str


@dataclasses.dataclass(frozen=True)
class FeatureTombstone:
    line_index: int
    text: str
    lineage: Lineage


class GitError(RuntimeError):
    pass


def git(*args: str) -> str:
    result = subprocess.run(
        ("git", *args), capture_output=True, text=True, check=False
    )
    if result.returncode:
        raise GitError(result.stderr.strip() or "git command failed")
    return result.stdout


def file_lines(revision: str, path: str) -> list[str]:
    result = subprocess.run(("git", "show", f"{revision}:{path}"),
                            stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                            check=False)
    if result.returncode or b"\0" in result.stdout:
        return []
    return result.stdout.decode("utf-8", "surrogateescape").splitlines()


def commits(base: str, tip: str) -> list[str]:
    return git("rev-list", "--reverse", "--first-parent", f"{base}..{tip}").splitlines()


def parents(commit: str) -> list[str]:
    return git("show", "-s", "--format=%P", commit).split()


def changed_paths(parent: str, commit: str,
                  pathspecs: tuple[str, ...]) -> list[tuple[str | None, str | None]]:
    raw = git(
        "diff", "--name-status", "-z", "-M", "--no-ext-diff",
        parent, commit, "--", *pathspecs,
    )
    fields = raw.split("\0")
    answer: list[tuple[str | None, str | None]] = []
    index = 0
    while index < len(fields) - 1:
        status = fields[index]
        index += 1
        if not status:
            continue
        if status[0] == "R":
            answer.append((fields[index], fields[index + 1]))
            index += 2
        elif status[0] == "C":
            answer.append((None, fields[index + 1]))
            index += 2
        elif status[0] == "D":
            answer.append((fields[index], None))
            index += 1
        elif status[0] == "A":
            answer.append((None, fields[index]))
            index += 1
        else:
            answer.append((fields[index], fields[index]))
            index += 1
    return answer


HUNK_HEADER = re.compile(
    r"^@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@"
)


def diff_hunks(parent: str, commit: str, old_path: str | None,
               new_path: str | None) -> list[DiffHunk]:
    paths = [f":(top,literal){path}" for path in (old_path, new_path) if path is not None]
    patch = git(
        "diff",
        "--unified=0",
        "--no-color",
        "--no-ext-diff",
        "--diff-algorithm=histogram",
        parent,
        commit,
        "--",
        *dict.fromkeys(paths),
    )
    hunks: list[DiffHunk] = []
    for line in patch.splitlines():
        match = HUNK_HEADER.match(line)
        if match is None:
            continue
        old_start, old_count_text, new_start, new_count_text = match.groups()
        old_count = int(old_count_text) if old_count_text is not None else 1
        new_count = int(new_count_text) if new_count_text is not None else 1
        old_position = int(old_start) if old_count == 0 else int(old_start) - 1
        new_position = int(new_start) if new_count == 0 else int(new_start) - 1
        hunks.append((old_position, old_count, new_position, new_count))
    return hunks


def carry_similar_replacements(old: list[str], old_ids: list[Lineage | None],
                               new: list[str], output: list[Lineage | None],
                               old_start: int, old_stop: int,
                               new_start: int, new_stop: int) -> tuple[set[int], set[int]]:
    candidates: list[tuple[float, int, int]] = []
    for old_index in range(old_start, old_stop):
        if old_ids[old_index] is None:
            continue
        old_normalized = normalized_line(old[old_index])
        for new_index in range(new_start, new_stop):
            score = difflib.SequenceMatcher(
                a=old_normalized,
                b=normalized_line(new[new_index]),
                autojunk=False,
            ).ratio()
            if score >= 0.72:
                candidates.append((score, old_index, new_index))
    matched_old: set[int] = set()
    matched_new: set[int] = set()
    for _score, old_index, new_index in sorted(candidates, reverse=True):
        if old_index not in matched_old and new_index not in matched_new:
            output[new_index] = old_ids[old_index]
            matched_old.add(old_index)
            matched_new.add(new_index)
    return matched_old, matched_new


def transition(old: list[str], old_ids: list[Lineage | None], new: list[str],
               hunks: list[DiffHunk]
               ) -> tuple[list[Lineage | None], list[tuple[Lineage | None, str, int]], list[int]]:
    """Apply Git's own hunk boundaries while carrying similar line edits."""
    output: list[Lineage | None] = [None] * len(new)
    removed: list[tuple[Lineage | None, str, int]] = []
    pending: list[int] = []
    old_cursor = 0
    new_cursor = 0
    for old_start, old_count, new_start, new_count in hunks:
        old_unchanged = old_start - old_cursor
        new_unchanged = new_start - new_cursor
        if old_unchanged != new_unchanged:
            raise GitError("Git hunk coordinates do not match file snapshots")
        unchanged = old_unchanged
        output[new_cursor:new_cursor + unchanged] = old_ids[old_cursor:old_cursor + unchanged]
        old_stop = old_start + old_count
        new_stop = new_start + new_count
        matched_old, matched_new = carry_similar_replacements(
            old, old_ids, new, output, old_start, old_stop, new_start, new_stop
        )
        removed.extend(
            (old_ids[index], old[index], index)
            for index in range(old_start, old_stop)
            if index not in matched_old
        )
        pending.extend(
            index for index in range(new_start, new_stop) if index not in matched_new
        )
        old_cursor = old_stop
        new_cursor = new_stop
    if len(old) - old_cursor != len(new) - new_cursor:
        raise GitError("Git trailing context does not match file snapshots")
    output[new_cursor:] = old_ids[old_cursor:]
    return output, removed, pending


def normalized_line(text: str) -> str:
    """Normalize whitespace for fuzzy in-place edit similarity."""
    return " ".join(text.split())


def move_normalized_line(text: str) -> str:
    """Ignore indentation only; internal whitespace may be semantically relevant."""
    return text.strip()


def contiguous_removed(lines: list[RemovedLine]) -> list[list[RemovedLine]]:
    groups: list[list[RemovedLine]] = []
    for line in sorted(lines, key=lambda item: (item.path, item.line_index)):
        if (groups and groups[-1][-1].path == line.path
                and groups[-1][-1].line_index + 1 == line.line_index):
            groups[-1].append(line)
        else:
            groups.append([line])
    return groups


def contiguous_added(lines: list[AddedLine]) -> list[list[AddedLine]]:
    groups: list[list[AddedLine]] = []
    for line in sorted(lines, key=lambda item: (item.path, item.line_index)):
        if (groups and groups[-1][-1].path == line.path
                and groups[-1][-1].line_index + 1 == line.line_index):
            groups[-1].append(line)
        else:
            groups.append([line])
    return groups


def sequence_occurrences(sequence: list[str], needle: tuple[str, ...]) -> int:
    size = len(needle)
    return sum(tuple(sequence[index:index + size]) == needle
               for index in range(len(sequence) - size + 1))


def confident_move_key(key: tuple[str, ...]) -> bool:
    """Reject low-information matches such as a coincidental closing ``fi``."""
    informative = sum(character.isalnum() for line in key for character in line)
    return informative >= 20 and (len(key) >= 2 or len(key[0]) >= 30)


def carry_confident_moves(removals: list[RemovedLine], additions: list[AddedLine]) -> tuple[set[int], set[int]]:
    """Carry identity over unique exact/whitespace-only moved blocks.

    The returned sets contain object indexes in ``removals`` and ``additions``
    that were consumed as moves.  Matching is intentionally conservative:
    blocks must be informative and occur exactly once on each side of this
    commit's diff. A single line needs at least 20 alphanumeric characters and
    30 total characters; shorter syntax such as ``fi`` is never called a move.
    """
    removal_groups = contiguous_removed(removals)
    addition_groups = contiguous_added(additions)
    removal_sequences = [[move_normalized_line(line.text) for line in group]
                         for group in removal_groups]
    addition_sequences = [[move_normalized_line(line.source_lines[line.line_index]) for line in group]
                          for group in addition_groups]
    candidates: list[tuple[int, int, int, int, int, tuple[str, ...]]] = []
    for removal_group_index, removal_sequence in enumerate(removal_sequences):
        for addition_group_index, addition_sequence in enumerate(addition_sequences):
            matcher = difflib.SequenceMatcher(
                a=removal_sequence, b=addition_sequence, autojunk=False
            )
            for match in matcher.get_matching_blocks():
                key = tuple(removal_sequence[match.a:match.a + match.size])
                if match.size and confident_move_key(key):
                    candidates.append((
                        match.size,
                        removal_group_index,
                        match.a,
                        addition_group_index,
                        match.b,
                        key,
                    ))
    consumed_removals: set[int] = set()
    consumed_additions: set[int] = set()
    removal_indexes = {id(line): index for index, line in enumerate(removals)}
    addition_indexes = {id(line): index for index, line in enumerate(additions)}
    for size, removal_group_index, removal_start, addition_group_index, addition_start, key in sorted(
            candidates, reverse=True):
        if sum(sequence_occurrences(sequence, key) for sequence in removal_sequences) != 1:
            continue
        if sum(sequence_occurrences(sequence, key) for sequence in addition_sequences) != 1:
            continue
        removal_block = removal_groups[removal_group_index][removal_start:removal_start + size]
        addition_block = addition_groups[addition_group_index][addition_start:addition_start + size]
        removal_ids = {removal_indexes[id(line)] for line in removal_block}
        addition_ids = {addition_indexes[id(line)] for line in addition_block}
        if removal_ids & consumed_removals or addition_ids & consumed_additions:
            continue
        for removed_line, added_line in zip(removal_block, addition_block, strict=True):
            added_line.identities[added_line.line_index] = removed_line.lineage
        consumed_removals.update(removal_ids)
        consumed_additions.update(addition_ids)
    return consumed_removals, consumed_additions


def analyse(base_ref: str, tip_ref: str,
            pathspecs: tuple[str, ...] = ()) -> list[LostLine]:
    base = git("merge-base", base_ref, tip_ref).strip()
    tip = git("rev-parse", "--verify", tip_ref).strip()
    state: dict[str, tuple[list[str], list[Lineage | None]]] = {}
    tombstones: dict[str, list[BaselineTombstone]] = collections.defaultdict(list)
    feature_tombstones: dict[str, list[FeatureTombstone]] = collections.defaultdict(list)
    lost: list[LostLine] = []
    branch_commits = commits(base, tip)
    indexes = {commit: index for index, commit in enumerate(branch_commits, start=1)}
    for commit in branch_commits:
        commit_parents = parents(commit)
        if not commit_parents:
            raise GitError(f"commit has no parent after merge-base: {commit}")
        is_merge = len(commit_parents) > 1
        parent = commit_parents[0]
        origin = Origin(commit, indexes[commit], git("show", "-s", "--format=%s", commit).strip())
        removals: list[RemovedLine] = []
        pending: list[AddedLine] = []
        updates: dict[str, tuple[list[str], list[Lineage | None]]] = {}
        for old_path, new_path in changed_paths(parent, commit, pathspecs):
            if old_path is None:
                old_text, old_ids = [], []
            else:
                old_text, old_ids = state.pop(old_path, (file_lines(parent, old_path), []))
                if not old_ids:
                    old_ids = [None] * len(old_text)
            new_text = [] if new_path is None else file_lines(commit, new_path)
            destination = new_path or old_path
            if destination is None:
                raise GitError(f"changed path is missing for commit {commit}")
            hunks = diff_hunks(parent, commit, old_path, new_path)
            old_changed_indexes = frozenset(
                index
                for old_start, old_count, _new_start, _new_count in hunks
                for index in range(old_start, old_start + old_count)
            )
            new_changed_indexes = frozenset(
                index
                for _old_start, _old_count, new_start, new_count in hunks
                for index in range(new_start, new_start + new_count)
            )
            new_ids, removed, additions = transition(old_text, old_ids, new_text, hunks)
            removals.extend(
                RemovedLine(
                    identity,
                    destination,
                    index,
                    text,
                    tuple(old_text),
                    old_changed_indexes,
                    tuple(hunks),
                    new_path is None,
                )
                for identity, text, index in removed
            )
            pending.extend(
                AddedLine(
                    destination,
                    index,
                    new_ids,
                    tuple(new_text),
                    new_changed_indexes,
                    tuple(hunks),
                    old_path is None,
                )
                for index in additions
            )
            if new_path is not None:
                updates[new_path] = (new_text, new_ids)
        moved_removals, moved_additions = carry_confident_moves(removals, pending)
        for pending_index, addition in enumerate(pending):
            if pending_index in moved_additions:
                continue
            text = addition.source_lines[addition.line_index]
            feature_restoration = next((
                tombstone
                for tombstone in feature_tombstones[addition.path]
                if tombstone.line_index == addition.line_index and tombstone.text == text
            ), None)
            restored = next((
                tombstone
                for tombstone in tombstones[addition.path]
                if tombstone.line_index == addition.line_index and tombstone.text == text
            ), None)
            if feature_restoration is not None:
                addition.identities[addition.line_index] = feature_restoration.lineage
                feature_tombstones[addition.path].remove(feature_restoration)
            elif restored is not None:
                tombstones[addition.path].remove(restored)
            elif is_merge:
                # First-parent merge diffs contain incoming upstream additions.
                # Carry known identities through the merge, but never call an
                # unmatched merge addition feature-born.
                addition.identities[addition.line_index] = None
            else:
                addition.identities[addition.line_index] = Lineage(
                    origin,
                    addition.path,
                    addition.line_index,
                    addition.source_lines,
                    addition.changed_indexes,
                    addition.hunks,
                    addition.file_added,
                )
        for removal_index, removal in enumerate(removals):
            if removal_index in moved_removals:
                continue
            if removal.lineage is None:
                tombstones[removal.path].append(BaselineTombstone(
                    removal.line_index,
                    removal.text,
                ))
            else:
                feature_tombstones[removal.path].append(FeatureTombstone(
                    removal.line_index,
                    removal.text,
                    removal.lineage,
                ))
                lost.append(LostLine(
                    removal.lineage,
                    commit,
                    indexes[commit],
                    origin.subject,
                    removal.path,
                    removal.text,
                    removal.line_index,
                    removal.source_lines,
                    removal.changed_indexes,
                    removal.hunks,
                    removal.file_deleted,
                ))
        state.update(updates)
    active_lineages = {
        lineage
        for _lines, identities in state.values()
        for lineage in identities
        if lineage is not None
    }
    latest_loss = {event.lineage: event for event in lost}
    return [
        event
        for event in lost
        if event.lineage not in active_lineages and latest_loss[event.lineage] is event
    ]


RESET, CYAN, GREEN, RED, YELLOW, DIM = "\x1b[0m", "\x1b[36m", "\x1b[32m", "\x1b[31m", "\x1b[33m", "\x1b[2m"


def colour(text: str, code: str, enabled: bool) -> str:
    return f"{code}{text}{RESET}" if enabled else text


def quoted_subject(subject: str) -> str:
    return subject.replace("\\", "\\\\").replace('"', '\\"')


def position_groups(indexes: set[int], changed_indexes: frozenset[int]) -> list[list[int]]:
    groups: list[list[int]] = []
    for index in sorted(indexes):
        blocked_between = groups and any(
            candidate in changed_indexes and candidate not in indexes
            for candidate in range(groups[-1][-1] + 1, index)
        )
        if groups and index <= groups[-1][-1] + 7 and not blocked_between:
            groups[-1].append(index)
        else:
            groups.append([index])
    return groups


def hunk_status(positions: list[int], all_kept_indexes: set[int],
                commit_hunks: tuple[DiffHunk, ...], prefix: str,
                whole_file: bool) -> str:
    side_offset = 2 if prefix == "+" else 0
    opposite_offset = 0 if prefix == "+" else 2
    related = [
        hunk
        for hunk in commit_hunks
        if any(
            hunk[side_offset] <= position < hunk[side_offset] + hunk[side_offset + 1]
            for position in positions
        )
    ]
    side_indexes = {
        index
        for hunk in related
        for index in range(hunk[side_offset], hunk[side_offset] + hunk[side_offset + 1])
    }
    kept = len(side_indexes & all_kept_indexes)
    total = len(side_indexes)
    opposite = sum(hunk[opposite_offset + 1] for hunk in related)
    action = "added" if prefix == "+" else "deleted"
    opposite_action = "removes" if prefix == "+" else "adds"
    if whole_file:
        parts = [f"whole-file {'add' if prefix == '+' else 'delete'}"]
        if kept == total and opposite == 0:
            parts.append("complete commit hunk")
    elif kept == total and opposite == 0:
        parts = ["complete commit hunk"]
    elif kept == total:
        parts = [f"complete {action} side"]
    else:
        parts = [f"filtered out {total - kept}/{total} {action} lines"]
        if len(positions) != kept:
            parts.append(f"showing {len(positions)} here")
    if opposite:
        parts.append(f"commit hunk also {opposite_action} {opposite}")
    if len(related) > 1:
        parts.append(f"combined {len(related)} commit hunks")
    return "; ".join(parts)


def render_hunks(chunks: list[str], path: str, source: tuple[str, ...], indexes: set[int],
                 changed_indexes: frozenset[int], commit_hunks: tuple[DiffHunk, ...],
                 file_added_or_deleted: bool, prefix: str, use_colour: bool,
                 include_file_header: bool) -> None:
    whole_file = file_added_or_deleted and indexes == set(range(len(source)))
    if include_file_header:
        chunks.extend((
            colour(f"diff --git a/{path} b/{path}", YELLOW, use_colour),
            colour(
                "--- /dev/null" if whole_file and prefix == "+" else f"--- a/{path}",
                RED,
                use_colour,
            ),
            colour(
                "+++ /dev/null" if whole_file and prefix == "-" else f"+++ b/{path}",
                GREEN,
                use_colour,
            ),
        ))
    for positions in position_groups(indexes, changed_indexes):
        start = positions[0]
        while start > 0 and positions[0] - start < 3 and start - 1 not in changed_indexes:
            start -= 1
        stop = positions[-1] + 1
        while stop < len(source) and stop - positions[-1] <= 3 and stop not in changed_indexes:
            stop += 1
        span = stop - start
        old_count, new_count = (span - len(positions), span) if prefix == "+" else (span, span - len(positions))
        old_line = start if old_count == 0 else start + 1
        new_line = start if new_count == 0 else start + 1
        status = hunk_status(positions, indexes, commit_hunks, prefix, whole_file)
        chunks.append(colour(
            f"@@ -{old_line},{old_count} +{new_line},{new_count} @@ [{status}]",
            CYAN,
            use_colour,
        ))
        for index in range(start, stop):
            marker = prefix if index in indexes else " "
            color = GREEN if marker == "+" else RED if marker == "-" else DIM
            chunks.append(colour(f"{marker}{source[index]}", color, use_colour))


def render(events: list[LostLine], *, use_colour: bool = False) -> str:
    births: dict[int, list[Lineage]] = collections.defaultdict(list)
    deaths: dict[int, list[LostLine]] = collections.defaultdict(list)
    for event in events:
        births[event.lineage.origin.index].append(event.lineage)
        deaths[event.removed_index].append(event)
    chunks: list[str] = []
    for commit_index in sorted(set(births) | set(deaths)):
        if chunks:
            chunks.append("")
        commit_births = set(births.get(commit_index, []))
        commit_deaths = deaths.get(commit_index, [])
        if commit_births:
            origin = next(iter(commit_births)).origin
            chunks.append(colour(f'#{origin.index} {quoted_subject(origin.subject)} ({origin.commit[:12]})', CYAN, use_colour))
        elif commit_deaths:
            event = commit_deaths[0]
            chunks.append(colour(f'#{event.removed_index} {quoted_subject(event.removed_subject)} ({event.removed_by[:12]})', CYAN, use_colour))
        births_by_path: dict[str, list[Lineage]] = collections.defaultdict(list)
        deaths_by_path: dict[str, list[LostLine]] = collections.defaultdict(list)
        for lineage in commit_births:
            births_by_path[lineage.birth_path].append(lineage)
        for event in commit_deaths:
            deaths_by_path[event.path].append(event)
        for path in sorted(set(births_by_path) | set(deaths_by_path)):
            header_emitted = False
            if path in births_by_path:
                lines = births_by_path[path]
                render_hunks(chunks, path, lines[0].birth_source_lines,
                             {line.birth_line_index for line in lines},
                             lines[0].birth_changed_indexes,
                             lines[0].birth_hunks,
                             lines[0].birth_file_added,
                             "+", use_colour, True)
                header_emitted = True
            if path in deaths_by_path:
                lines = deaths_by_path[path]
                render_hunks(chunks, path, lines[0].source_lines,
                             {line.line_index for line in lines},
                             lines[0].removal_changed_indexes,
                             lines[0].removal_hunks,
                             lines[0].removal_file_deleted,
                             "-", use_colour, not header_emitted)
    return "\n".join(chunks) + ("\n" if chunks else "")


def split_revision_range(base: str, feature: str | None,
                         paths: tuple[str, ...]) -> tuple[str, str, tuple[str, ...]]:
    for separator in ("...", ".."):
        if separator in base:
            base_ref, tip_ref = base.split(separator, maxsplit=1)
            range_paths = ((feature,) if feature is not None else ()) + paths
            if not base_ref:
                raise GitError(f"missing base before {separator}")
            return base_ref, tip_ref or "HEAD", range_paths
    return base, feature or "HEAD", paths


def default_pathspecs() -> tuple[str, ...]:
    repository_root = Path(git("rev-parse", "--show-toplevel").strip()).resolve()
    current_directory = Path.cwd().resolve()
    try:
        relative_directory = current_directory.relative_to(repository_root)
    except ValueError as error:
        raise GitError(f"current directory is outside Git root {repository_root}") from error
    return () if relative_directory == Path(".") else (".",)


def main(argv: list[str] | None = None) -> int:
    raw_arguments = list(sys.argv[1:] if argv is None else argv)
    explicit_paths: tuple[str, ...] = ()
    if "--" in raw_arguments:
        separator_index = raw_arguments.index("--")
        explicit_paths = tuple(raw_arguments[separator_index + 1:])
        raw_arguments = raw_arguments[:separator_index]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--color", "--colour", dest="color", nargs="?", const="always",
                        choices=("auto", "always", "never"), default="auto")
    parser.add_argument("base", help="integration ref, e.g. main")
    parser.add_argument("feature", nargs="?", default=None, help="feature tip (default: HEAD)")
    parser.add_argument("paths", nargs="*", help="Git pathspecs (prefer after --)")
    args = parser.parse_args(raw_arguments)
    try:
        base_ref, tip_ref, positional_paths = split_revision_range(
            args.base,
            args.feature,
            tuple(args.paths),
        )
        pathspecs = positional_paths + explicit_paths
        if not pathspecs:
            pathspecs = default_pathspecs()
        use_colour = args.color == "always" or (args.color == "auto" and sys.stdout.isatty() and "NO_COLOR" not in os.environ)
        output = render(
            analyse(base_ref, tip_ref, pathspecs),
            use_colour=use_colour,
        )
    except GitError as error:
        print(f"transient-diff: {error}", file=sys.stderr)
        return 2
    try:
        sys.stdout.write(output)
        sys.stdout.flush()
    except BrokenPipeError:
        try:
            sys.stdout.close()
        except BrokenPipeError:
            pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
