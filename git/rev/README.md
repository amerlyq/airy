# transient-diff

`transient_diff.py` finds lines born on a feature branch that disappeared before
the branch tip.  It is a companion to, not a replacement for,
`git diff main...feature`.

Requires Python 3.12 or later (including Python 3.14); it uses only the
standard library.

```bash
python3 /path/to/transient_diff.py main feature
# or, while on the feature branch:
python3 /path/to/transient_diff.py main
```

Filter with Git pathspecs after `--`, or use a single Git-style revision range:

```bash
python3 /path/to/transient_diff.py main feature -- silver/Dockerfile.silver silver/env
python3 /path/to/transient_diff.py main...feature -- silver/
```

Explicit pathspecs are interpreted relative to the current directory, like
Git. With no pathspec, running at the repository root analyzes the whole tree;
running from a subdirectory defaults to that subdirectory (`.`).

The output is colourized on a terminal.  It is regular unified-diff-shaped
text, so it can be rendered with delta:

```bash
python3 /path/to/transient_diff.py main feature | delta
```

Use `--color=always` to retain this tool's ANSI colours through another pipe,
or `--color=never` for plain output.  A downstream pager/filter closing early
is handled quietly rather than producing a `BrokenPipeError` traceback.

Output is a chronological, filtered patch series.  Each transient line appears
as a normal `+` hunk in the commit that introduced it and a normal `-` hunk in
the later commit that removed it.  Nearby lines from the same path and commit
are coalesced into one hunk with up to three surrounding context lines.
It has no third-party dependencies and ignores binary files.

Each commit annotation is formatted as `#<number> <subject> (<short-sha>)`,
where the number is its one-based position in the first-parent feature history
after the merge-base.

Hunk headers describe whether the filtered view contains the complete original
commit hunk, how many same-side lines were filtered out, whether the original
hunk also changed the opposite side, and whether nearby commit hunks were
combined. Whole-file additions and deletions are labeled and use `/dev/null`
in their file headers, like ordinary Git patches.

## Semantics and limits

The tool walks `merge-base(base, feature)..feature` in first-parent order.  It
only creates lineage records for added lines, carries records through ordinary
in-place edits when their whitespace-normalized text is sufficiently similar,
and carries unique, informative blocks across exact or indentation-only moves
(including across paths). Baseline identity is carried through those moves as
well. A single-line match must be long and distinctive; short or ambiguous
matches such as a lone `fi` are deliberately not classified as moves. A lineage
still present at the feature tip is never printed.
Thus baseline lines temporarily deleted and restored are not the target.
Exact same-path, same-position remove/re-add cycles restore the prior lineage.
If that lineage survives at the tip it is omitted; if it ultimately disappears,
the cycle is grouped as its original birth and terminal removal.

Merge commits carry existing feature lineages through their first-parent diff,
but unmatched merge additions are classified as upstream/baseline content.
This avoids calling changes merged from main feature-born. Manual conflict
resolution additions made only in the merge commit are therefore conservatively
ignored, while a feature line born before a merge can still be reported if it
is removed afterward.
Exact outcomes also depend on Git rename detection and the line matching
heuristic, particularly for large rewrites or ambiguous duplicate lines.
Reformatted or substantially edited moves are intentionally allowed to appear
as redundant review output rather than being guessed to be a move.


Key guarantees now:

- Uses Git’s own histogram hunk boundaries for per-commit attribution.
- Excludes lineages surviving in the final diff, including remove/re-add cycles.
- Preserves baseline identity across confirmed same/cross-file moves.
- Suppresses only unique, informative exact or indentation-only moves.
- Does not classify ambiguous tokens such as fi as moves.
- Handles merges from main without treating incoming upstream lines as feature-born.
- Context contains only lines unchanged in that individual commit.
