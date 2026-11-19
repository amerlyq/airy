"""Duration sorting batches metadata and formats user-facing durations."""

from types import SimpleNamespace

import pytest

from plugins import vddur_sort_linemode as duration


def test_duration_linemode_formats_minutes_and_default_fallback(monkeypatch):
    mode = duration.DurationLinemode()
    monkeypatch.setattr(
        duration, "get_duration_mediainfo", lambda path, st=None: 65_123
    )
    monkeypatch.setattr(duration, "_st", lambda f: None)
    fallback = SimpleNamespace(infostring=lambda f, metadata: "fallback")
    media = SimpleNamespace(
        path="/x.mp4",
        basename="x.mp4",
        relative_path="x.mp4",
        is_file=True,
        video=True,
        audio=False,
        size=2 * 1024 * 1024,
        linemode_dict={"filename": fallback},
    )
    assert mode.infostring(media, None) == "(2.0M) 1:05.123"
    other = SimpleNamespace(
        is_file=False, video=False, audio=False, linemode_dict={"filename": fallback}
    )
    assert mode.infostring(other, None) == "fallback"


def test_duration_groups_sorts_by_duration_and_batches_paths(monkeypatch):
    files = [SimpleNamespace(path=f"/{i}", is_directory=False) for i in range(3)]
    calls = []
    monkeypatch.setattr(
        duration.vdprobe,
        "many",
        lambda paths: (
            calls.append(paths) or {"/0": (1100,), "/1": (1000,), "/2": (3000,)}
        ),
    )
    groups = duration.duration_groups(files, tolerance=200)
    assert [[f.path for f in group] for group in groups] == [["/1", "/0"], ["/2"]]
    assert calls == [["/0", "/1", "/2"]]


def make_duration_fm(filter_stack=None, sort="natural"):
    commands = []
    notices = []
    redraws = []
    directory = SimpleNamespace(
        path="/media",
        filter_stack=list(filter_stack or []),
        files_all=[SimpleNamespace(display_data={"cached": True})],
        settings=SimpleNamespace(sort=sort),
        refilter=lambda: commands.append("refilter"),
        sort=lambda: commands.append("sort"),
    )

    def execute_console(command):
        commands.append(command)
        if command.startswith("setlocal sort="):
            directory.settings.sort = command.removeprefix("setlocal sort=")
        if command == "filter_stack clear":
            directory.filter_stack.clear()

    fm = SimpleNamespace(
        thisdir=directory,
        execute_console=execute_console,
        notify=lambda *a, **kw: notices.append((a, kw)),
        ui=SimpleNamespace(redraw_main_column=lambda: redraws.append(True)),
    )
    return fm, commands, notices, redraws


def test_view_duration_on_then_toggle_off_restores_view_state(monkeypatch):
    from plugins import clip_grouping

    transitions = []
    monkeypatch.setattr(
        clip_grouping,
        "enter_duration_view",
        lambda path: transitions.append(("enter", path)),
    )
    monkeypatch.setattr(
        clip_grouping,
        "leave_duration_view",
        lambda path: transitions.append(("leave", path)),
    )
    fm, commands, notices, redraws = make_duration_fm()

    command = duration.view_duration("view_duration on grayout")
    command.fm = fm
    command.execute()

    active = fm.thisdir.filter_stack[0]
    assert isinstance(active, duration.DurationFilter)
    assert active.grayout is True
    assert fm.thisdir.settings.sort == "duration"
    assert "setlocal sort_reverse=True" in commands
    assert transitions == [("enter", "/media")]
    assert redraws == [True]
    assert fm.thisdir.files_all[0].display_data == {}

    toggle = duration.view_duration("view_duration toggle")
    toggle.fm = fm
    toggle.execute()
    assert fm.thisdir.filter_stack == []
    assert fm.thisdir.settings.sort == "natural"
    assert "filter_stack clear" in commands
    assert transitions[-1] == ("leave", "/media")
    assert notices == []


def test_toggle_restores_sort_without_replacing_active_grayout_filter(monkeypatch):
    from plugins import clip_grouping

    monkeypatch.setattr(
        clip_grouping,
        "enter_duration_view",
        lambda _path: pytest.fail("must not re-enter"),
    )
    monkeypatch.setattr(
        clip_grouping,
        "leave_duration_view",
        lambda _path: pytest.fail("must not leave"),
    )
    existing = duration.DurationFilter("", grayout=True)
    fm, commands, _notices, _redraws = make_duration_fm([existing], sort="natural")

    command = duration.view_duration("view_duration toggle")
    command.fm = fm
    command.execute()

    assert fm.thisdir.filter_stack == [existing]
    assert existing.grayout is True
    assert fm.thisdir.settings.sort == "duration"
    assert all(
        not isinstance(item, duration.DurationFilter) or item is existing
        for item in fm.thisdir.filter_stack
    )
    assert not any("clip_sorting" in command for command in commands)


def test_duration_filter_recomputes_when_directory_listing_changes(monkeypatch):
    files = [
        SimpleNamespace(path="/media/a", is_directory=False),
        SimpleNamespace(path="/media/b", is_directory=False),
    ]
    directory = SimpleNamespace(path="/media", files_all=files)
    scans = []

    def groups(items, tolerance):
        scans.append(tuple(file.path for file in items))
        return [[items[0], items[1]]] if len(items) == 2 else [[items[1], items[2]]]

    monkeypatch.setattr(duration, "duration_groups", groups)
    fm = SimpleNamespace(get_directory=lambda _path: directory)
    monkeypatch.setattr(duration.DurationFilter, "fm", fm, raising=False)
    filt = duration.DurationFilter("")

    assert filt.paired(directory, files[0])
    assert filt.paired(directory, files[1])
    directory.files_all = [*files, SimpleNamespace(path="/media/c", is_directory=False)]
    assert not filt.paired(directory, files[0])
    assert filt.paired(directory, directory.files_all[2])
    assert len(scans) == 2


def test_view_duration_rejects_unknown_options():
    fm, _commands, notices, _redraws = make_duration_fm()
    command = duration.view_duration("view_duration on mystery")
    command.fm = fm
    command.execute()
    assert notices and notices[0][1]["bad"] is True
    assert notices[0][0][0].startswith("Usage: view_duration")
