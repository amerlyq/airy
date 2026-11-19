"""Shared VD configuration exposes supported refresh and clip naming defaults."""

import re

from plugins import vdconf


def test_refresh_default_and_bounded_monitor_settings():
    assert vdconf.REFRESH in {"validate", "visited", "none"}
    assert vdconf.DANGLING_MONITOR is True
    assert vdconf.DANGLING_WORKERS > 0
    assert vdconf.DANGLING_BUDGET > 0
    assert vdconf.DANGLING_REVALIDATE > vdconf.DANGLING_QUIET


def test_clip_suffix_pattern_accepts_supported_token_chains():
    suffix = re.compile(r"(?:^|_)" + vdconf.CLIP_SUFFIX + r"$")
    assert suffix.search("movie_00m33s6")
    assert suffix.search("movie_v32_prev29267")
    assert not suffix.search("movie_notes_final")
