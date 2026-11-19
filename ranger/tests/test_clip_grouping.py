"""Clip naming, stable Ranger sorting, and display-only grouping behavior."""

from types import SimpleNamespace

import pytest

from plugins import clip_grouping as grouping


def entry(name, *, directory=False):
    return SimpleNamespace(
        basename=name,
        relative_path=name,
        is_directory=directory,
        display_data={},
    )


def test_clip_source_recognizes_supported_suffix_chains():
    assert grouping.clip_source(entry("Movie_03m12s5_v4.mp4")) == "movie"
    assert grouping.clip_source(entry("Movie_prev123.mp4")) == "movie"
    assert grouping.clip_source(entry("Movie.mp4")) is None
    assert grouping.clip_source(entry("Movie_notes_final.mp4")) is None


def test_sort_groups_clips_after_original_and_keeps_directories_and_stable_order():
    files = [
        entry("zeta_12m3s4.mp4"),
        entry("Beta.mp4"),
        entry("folder", directory=True),
        entry("zeta.mp4"),
        entry("Beta_v2.mp4"),
        entry("zeta_v3.mp4"),
    ]
    directory = SimpleNamespace(
        files_all=files,
        refilter=lambda: None,
    )
    refiltered = []
    directory.refilter = lambda: refiltered.append(
        [file.basename for file in directory.files_all]
    )

    grouping.GROUP_CLIPS_ENABLED = True
    grouping._make_sort(lambda _self: None)(directory)

    assert [file.basename for file in files] == [
        "Beta.mp4",
        "Beta_v2.mp4",
        "folder",
        "zeta.mp4",
        "zeta_12m3s4.mp4",
        "zeta_v3.mp4",
    ]
    assert refiltered == [[file.basename for file in files]]


def test_duration_view_restores_exact_grouping_preferences():
    path = "/tmp/duration-view"
    previous = (
        grouping.GROUP_DECOR_MODE,
        grouping.GROUP_CLIPS_ENABLED,
        grouping.DECORATE_CLIP_NAMES,
    )
    grouping._DURATION_SAVED_MODES.pop(path, None)
    grouping.enter_duration_view(path)
    assert not grouping.GROUP_DECOR_MODE
    assert not grouping.GROUP_CLIPS_ENABLED
    assert not grouping.DECORATE_CLIP_NAMES
    grouping.GROUP_CLIPS_ENABLED = True  # duration linemode may change flags

    grouping.leave_duration_view(path)

    assert (
        grouping.GROUP_DECOR_MODE,
        grouping.GROUP_CLIPS_ENABLED,
        grouping.DECORATE_CLIP_NAMES,
    ) == previous


@pytest.mark.benchmark
def test_sort_work_is_linearithmic_for_large_synthetic_directories():
    import time

    files = [entry(f"movie_{index:05d}_v2.mp4") for index in range(10_000)]
    directory = SimpleNamespace(files_all=files, refilter=lambda: None)
    sort = grouping._make_sort(lambda _self: None)
    started = time.perf_counter()
    sort(directory)
    assert time.perf_counter() - started < 3
