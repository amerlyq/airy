"""Context colors for workflow directories, clips, and links."""

from types import SimpleNamespace

from plugins import airy_colorscheme as colors


def test_workflow_directory_and_suffix_colors_are_added():
    cases = [
        ("arc", "wf_log"),
        ("todo", "wf_todo"),
        ("&ref", "wf_ref"),
        ("_gen", "wf_gen"),
        ("#misc", "wf_misc"),
    ]
    for name, color in cases:
        _, result = colors.new_hook_before_drawing(
            SimpleNamespace(
                basename=name, is_file=False, is_directory=True, is_link=False
            ),
            [],
        )
        assert color in result
    file = SimpleNamespace(
        basename="episode.nou",
        is_file=True,
        is_directory=False,
        is_link=False,
        video=False,
    )
    assert "ext_nou" in colors.new_hook_before_drawing(file, [])[1]


def test_clip_color_identifies_v32_variant():
    file = SimpleNamespace(
        basename="scene_v32_v1.mp4",
        is_file=True,
        is_directory=False,
        is_link=False,
        video=True,
    )
    assert "clip_v32" in colors.new_hook_before_drawing(file, [])[1]
