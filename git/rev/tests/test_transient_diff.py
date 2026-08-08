import subprocess
import sys
from pathlib import Path

TOOL = Path(__file__).parents[1] / "transient_diff.py"


def run(repo: Path, *args: str) -> str:
    return subprocess.run(
        args, cwd=repo, text=True, check=True, capture_output=True
    ).stdout


def commit(repo: Path, message: str) -> None:
    run(repo, "git", "add", ".")
    run(repo, "git", "commit", "-qm", message)


def test_reports_branch_added_line_then_removed_with_attribution(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.py").write_text("before\nafter\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.py").write_text("before\n# explain why this is needed\nafter\n")
    commit(repo, "add explanation")
    (repo / "a.py").write_text("before\nafter\n")
    commit(repo, "remove explanation")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")

    assert "#1 add explanation (" in output
    assert "#2 remove explanation (" in output
    assert "\n\n#2 remove explanation (" in output
    assert "+# explain why this is needed" in output
    assert "-# explain why this is needed" in output
    assert " before" in output and " after" in output


def test_does_not_report_line_that_survives_or_an_exact_move(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "one.txt").write_text("base\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "one.txt").write_text("base\ntransient block first\ntransient block second\nsurvives\n")
    commit(repo, "add lines")
    (repo / "one.txt").write_text("base\nsurvives\n")
    (repo / "two.txt").write_text("transient block first\ntransient block second\n")
    commit(repo, "move line")

    assert run(repo, sys.executable, str(TOOL), "main", "feature") == ""


def test_baseline_block_moved_across_paths_is_not_feature_born(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "old.txt").write_text("baseline block first\nbaseline block second\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "old.txt").write_text("")
    (repo / "new.txt").write_text("  baseline block first\n  baseline block second\n")
    commit(repo, "move and indent baseline block")
    (repo / "new.txt").write_text("")
    commit(repo, "remove moved baseline block")

    assert run(repo, sys.executable, str(TOOL), "main", "feature") == ""


def test_distinctive_baseline_line_moved_across_paths_keeps_identity(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    line = "distinctive baseline configuration value = enabled\n"
    (repo / "old.txt").write_text(line + "line that stays in the source file\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "old.txt").write_text("line that stays in the source file\n")
    (repo / "new.txt").write_text(line)
    commit(repo, "move baseline line")
    (repo / "new.txt").unlink()
    commit(repo, "remove moved baseline line")

    assert run(repo, sys.executable, str(TOOL), "main", "feature") == ""


def test_ambiguous_single_line_is_not_suppressed_as_a_move(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "base.txt").write_text("baseline\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "one.sh").write_text("fi\n")
    commit(repo, "create first closing token")
    (repo / "one.sh").write_text("")
    (repo / "two.sh").write_text("fi\n")
    commit(repo, "recreate closing token elsewhere")
    (repo / "two.sh").write_text("")
    commit(repo, "remove second closing token")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")

    assert output.splitlines().count("+fi") == 2
    assert output.splitlines().count("-fi") == 2


def test_internal_whitespace_change_is_not_proven_move(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "base.txt").write_text("baseline\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "one.txt").write_text(
        'value = "a  b"\nsecond distinctive line\nold extra one\nold extra two\n'
        "old extra three\nold extra four\n"
    )
    commit(repo, "create original block")
    (repo / "one.txt").unlink()
    (repo / "two.txt").write_text('value = "a b"\nsecond distinctive line\n')
    commit(repo, "recreate changed block")
    (repo / "two.txt").unlink()
    commit(repo, "remove changed block")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")

    assert '+value = "a  b"' in output
    assert '-value = "a  b"' in output
    assert '+value = "a b"' in output
    assert '-value = "a b"' in output


def test_merge_carries_feature_lineage_but_not_upstream_origin(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "feature.txt").write_text("base\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "feature.txt").write_text("base\nfeature transient\n")
    commit(repo, "add feature transient")
    run(repo, "git", "switch", "main")
    (repo / "upstream.txt").write_text("upstream first\nupstream second\n")
    commit(repo, "upstream work")
    run(repo, "git", "switch", "feature")
    run(repo, "git", "merge", "-qm", "merge main", "main")
    (repo / "feature.txt").write_text("base\n")
    (repo / "upstream.txt").unlink()
    commit(repo, "remove transient and upstream file")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")

    assert "+feature transient" in output
    assert "-feature transient" in output
    assert "upstream first" not in output
    assert "upstream second" not in output


def test_does_not_report_a_main_line_deleted_then_restored(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.txt").write_text("main line\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.txt").write_text("")
    commit(repo, "remove main line")
    (repo / "a.txt").write_text("main line\n")
    commit(repo, "restore main line")

    assert run(repo, sys.executable, str(TOOL), "main", "feature") == ""


def test_same_baseline_text_at_new_position_is_feature_born(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.sh").write_text("fi\nanchor\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.sh").write_text("anchor\n")
    commit(repo, "delete baseline closing token")
    (repo / "a.sh").write_text("anchor\nfi\n")
    commit(repo, "create unrelated closing token")
    (repo / "a.sh").write_text("anchor\n")
    commit(repo, "remove unrelated closing token")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")

    assert "+fi" in output
    assert "-fi" in output


def test_readded_line_surviving_at_tip_is_left_to_total_diff(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.txt").write_text("before\nafter\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.txt").write_text("before\nfeature line\nafter\n")
    commit(repo, "add feature line")
    (repo / "a.txt").write_text("before\nafter\n")
    commit(repo, "temporarily remove feature line")
    (repo / "a.txt").write_text("before\nfeature line\nafter\n")
    commit(repo, "restore feature line")

    assert run(repo, sys.executable, str(TOOL), "main", "feature") == ""


def test_repeated_cycle_is_grouped_to_birth_and_terminal_removal(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.txt").write_text("before\nafter\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.txt").write_text("before\nfeature line\nafter\n")
    commit(repo, "add feature line")
    (repo / "a.txt").write_text("before\nafter\n")
    commit(repo, "first removal")
    (repo / "a.txt").write_text("before\nfeature line\nafter\n")
    commit(repo, "restore feature line")
    (repo / "a.txt").write_text("before\nafter\n")
    commit(repo, "terminal removal")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")

    assert output.count("+feature line") == 1
    assert output.count("-feature line") == 1
    assert "#2 first removal" not in output
    assert "#4 terminal removal" in output


def test_pathspec_and_subdirectory_default_filtering(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "one").mkdir()
    (repo / "two").mkdir()
    (repo / "one" / "a.txt").write_text("one base\n")
    (repo / "two" / "b.txt").write_text("two base\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "one" / "a.txt").write_text("one base\none transient\n")
    (repo / "two" / "b.txt").write_text("two base\ntwo transient\n")
    commit(repo, "add transient lines")
    (repo / "one" / "a.txt").write_text("one base\n")
    (repo / "two" / "b.txt").write_text("two base\n")
    commit(repo, "remove transient lines")

    explicit = run(
        repo,
        sys.executable,
        str(TOOL),
        "main...feature",
        "--",
        "two/b.txt",
    )
    nested = subprocess.run(
        (sys.executable, str(TOOL), "main", "feature"),
        cwd=repo / "one",
        text=True,
        check=True,
        capture_output=True,
    ).stdout

    assert "two transient" in explicit
    assert "one transient" not in explicit
    assert "one transient" in nested
    assert "two transient" not in nested


def test_color_always_emits_ansi_sequences(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.txt").write_text("base\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.txt").write_text("base\ntemporary\n")
    commit(repo, "add temporary")
    (repo / "a.txt").write_text("base\n")
    commit(repo, "remove temporary")

    output = run(repo, sys.executable, str(TOOL), "--color=always", "main", "feature")

    assert "\x1b[" in output
    assert "-temporary" in output


def test_nearby_lost_lines_are_rendered_as_one_hunk(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.txt").write_text("before\nafter\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.txt").write_text("before\nfirst temporary\nsecond temporary\nafter\n")
    commit(repo, "add temporary lines")
    (repo / "a.txt").write_text("before\nafter\n")
    commit(repo, "remove temporary lines")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")

    assert output.count("diff --git") == 2
    assert "+first temporary\n+second temporary" in output
    assert "-first temporary\n-second temporary" in output


def test_distant_hunks_share_one_file_header_per_commit(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    baseline = [f"baseline {index}" for index in range(20)]
    (repo / "a.txt").write_text("\n".join(baseline) + "\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    with_transients = baseline[:2] + ["first transient"] + baseline[2:17] + ["second transient"] + baseline[17:]
    (repo / "a.txt").write_text("\n".join(with_transients) + "\n")
    commit(repo, "add distant transient lines")
    (repo / "a.txt").write_text("\n".join(baseline) + "\n")
    commit(repo, "remove distant transient lines")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")

    assert output.count("diff --git a/a.txt b/a.txt") == 2
    assert sum(line.startswith("@@ ") for line in output.splitlines()) == 4


def test_birth_and_death_hunks_share_file_header_in_same_commit(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.txt").write_text("baseline\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.txt").write_text("first transient implementation\n")
    commit(repo, "add first transient")
    (repo / "a.txt").write_text("unrelated second transient design\n")
    commit(repo, "replace transient")
    (repo / "a.txt").write_text("baseline\n")
    commit(repo, "remove second transient")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")
    replacement_section = output.split("\n\n#2", maxsplit=1)[1].split("\n\n#3", maxsplit=1)[0]

    assert replacement_section.count("diff --git a/a.txt b/a.txt") == 1
    assert "+unrelated second transient design" in replacement_section
    assert "-first transient implementation" in replacement_section


def test_whole_file_hunks_use_dev_null_and_status(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "base.txt").write_text("base\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "temporary.txt").write_text("first temporary\nsecond temporary\n")
    commit(repo, "add temporary file")
    (repo / "temporary.txt").unlink()
    commit(repo, "delete temporary file")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")

    assert "--- /dev/null\n+++ b/temporary.txt" in output
    assert "--- a/temporary.txt\n+++ /dev/null" in output
    assert "[whole-file add; complete commit hunk]" in output
    assert "[whole-file delete; complete commit hunk]" in output


def test_surviving_change_is_not_rendered_as_birth_context(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.txt").write_text("before\nafter\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.txt").write_text("before\ntransient\nsurviving final line\nafter\n")
    commit(repo, "add transient and final lines")
    (repo / "a.txt").write_text("before\nsurviving final line\nafter\n")
    commit(repo, "remove transient")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")
    birth_section = output.split("\n\n#2", maxsplit=1)[0]

    assert "+transient" in birth_section
    assert "surviving final line" not in birth_section
    assert "[filtered out 1/2 added lines]" in birth_section


def test_unrelated_replacement_does_not_hide_a_lost_feature_line(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.txt").write_text("baseline\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.txt").write_text("feature-specific explanatory comment\n")
    commit(repo, "add explanation")
    (repo / "a.txt").write_text("unrelated replacement implementation\n")
    commit(repo, "rewrite")

    output = run(repo, sys.executable, str(TOOL), "main", "feature")

    assert "-feature-specific explanatory comment" in output


def test_similar_edit_retains_feature_lineage(tmp_path: Path) -> None:
    repo = tmp_path / "repo"
    repo.mkdir()
    run(repo, "git", "init", "-q", "-b", "main")
    run(repo, "git", "config", "user.email", "test@example.invalid")
    run(repo, "git", "config", "user.name", "Test")
    (repo / "a.txt").write_text("baseline\n")
    commit(repo, "base")
    run(repo, "git", "switch", "-qc", "feature")
    (repo / "a.txt").write_text("# explain the package cache behaviour\n")
    commit(repo, "add explanation")
    (repo / "a.txt").write_text("# explain the updated package cache behaviour\n")
    commit(repo, "refine explanation")

    assert run(repo, sys.executable, str(TOOL), "main", "feature") == ""
