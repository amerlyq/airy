"""Flat inode filtering predicates and command validation."""

from types import SimpleNamespace

from plugins import cmd_view
from plugins.cmd_view import _InodeTypeFilter, flat_inode


def test_inode_filter_selects_file_directory_and_link_types():
    filt = _InodeTypeFilter("f")
    assert filt(SimpleNamespace(is_directory=False, is_file=True, is_link=False))
    assert (
        filt(SimpleNamespace(is_directory=False, is_file=True, is_link=True)) is False
    )
    assert _InodeTypeFilter("l")(
        SimpleNamespace(is_directory=False, is_file=True, is_link=True)
    )
    assert (
        filt(SimpleNamespace(is_directory=True, is_file=False, is_link=False)) is False
    )
    assert str(filt) == "inode type: f"


def test_flat_inode_bad_level_reports_actionable_error():
    calls = []
    cmd = flat_inode("flat_inode f nope")
    cmd.fm = SimpleNamespace(notify=lambda *a, **kw: calls.append((a, kw)))
    cmd.execute()
    assert "level must be an integer" in calls[0][0][0]
    assert calls[0][1]["bad"] is True


def test_flat_inode_activation_captures_visible_entries_and_toggle_unsets():
    file = SimpleNamespace(
        path="/root/visible", is_file=True, is_link=False, is_directory=False
    )
    directory = SimpleNamespace(
        files_all=[file],
        files=[file],
        flat=0,
        loading=False,
        filter_stack=[],
        refilter=lambda: None,
    )
    calls = []

    def execute_console(line):
        calls.append(line)
        if line.startswith("flat "):
            directory.flat = int(line.split()[1])

    fm = SimpleNamespace(
        thisdir=directory,
        execute_console=execute_console,
        notify=lambda *_a, **_kw: None,
    )

    cmd = flat_inode("flat_inode f 2")
    cmd.fm = fm
    cmd.execute()

    inode_filter = directory.filter_stack[0]
    assert isinstance(inode_filter, _InodeTypeFilter)
    assert inode_filter(file)
    assert directory._flat_inode_active is True
    assert directory._flat_inode_entries == {file.path}
    assert calls == ["flat 2"]

    toggle = flat_inode("flat_inode -t f 2")
    toggle.fm = fm
    toggle.execute()
    assert directory.flat == 0
    assert directory.filter_stack == []
    assert directory._flat_inode_active is False
    assert directory._flat_inode_entries is None
    assert calls[-1] == "flat 0"


def test_flat_inode_unset_flag_restores_unflattened_view():
    file = SimpleNamespace(
        path="/root/visible", is_file=True, is_link=False, is_directory=False
    )
    directory = SimpleNamespace(
        files_all=[file],
        files=[file],
        flat=3,
        loading=False,
        filter_stack=[_InodeTypeFilter("f")],
        refilter=lambda: None,
    )
    calls = []
    cmd = flat_inode("flat_inode u")
    cmd.fm = SimpleNamespace(
        thisdir=directory, execute_console=calls.append, notify=lambda *_a, **_kw: None
    )
    cmd.execute()
    assert directory.filter_stack == []
    assert directory._flat_inode_active is False
    assert directory._flat_inode_entries is None
    assert calls == ["flat 0"]


def test_flat_inode_loads_unloaded_directory_and_restores_previous_flat_value():
    file = SimpleNamespace(
        path="/root/visible", is_file=True, is_link=False, is_directory=False
    )
    calls = []
    directory = SimpleNamespace(
        files_all=None,
        files=None,
        flat=3,
        loading=True,
        filter_stack=[],
        unload=lambda: calls.append("unload"),
        load_content=lambda **kw: (
            calls.append(kw),
            setattr(directory, "files_all", [file]),
            setattr(directory, "files", [file]),
        ),
        refilter=lambda: None,
    )

    def execute_console(line):
        calls.append(line)
        if line.startswith("flat "):
            directory.flat = int(line.split()[1])

    cmd = flat_inode("flat_inode d 2")
    cmd.fm = SimpleNamespace(
        thisdir=directory,
        execute_console=execute_console,
        notify=lambda *_a, **_kw: None,
    )
    cmd.execute()
    assert calls[:2] == ["unload", {"schedule": False}]
    assert (
        directory.flat == 2
    )  # the requested new flat depth runs after restoring the old value
    assert directory._flat_inode_entries == {file.path}
    assert calls[-1] == "flat 2"


def test_filtered_walklevel_prunes_prefiltered_and_hidden_entries(monkeypatch):
    root = "/root"
    visible = {"/root/keep", "/root/file.txt"}
    directory = SimpleNamespace(path=root)
    source_dirs = ["keep", "hidden", "filtered"]
    source_files = ["file.txt", "hidden.txt", "filtered.txt"]
    monkeypatch.setattr(
        cmd_view,
        "_walklevel",
        lambda _path, _level: iter([(root, source_dirs.copy(), source_files.copy())]),
    )
    cmd_view._flat_context.value = [
        directory,
        visible,
        cmd_view.re.compile(r"^hidden"),
        True,
    ]
    try:
        _root, dirs, files = next(cmd_view._filtered_walklevel(root, 2))
    finally:
        cmd_view._flat_context.value = None
    assert dirs == ["keep"]
    assert files == ["file.txt"]


def test_filtered_load_bit_by_bit_clears_thread_context_on_early_stop(monkeypatch):
    directory = SimpleNamespace(
        flat=2,
        _flat_inode_active=True,
        _flat_inode_entries={"/root/keep", "/root/keep.txt"},
        settings=SimpleNamespace(show_hidden=False, hidden_filter=r"^\."),
        path="/root",
    )
    root = "/root"
    monkeypatch.setattr(
        cmd_view,
        "_walklevel",
        lambda _path, _level: iter(
            [(root, ["keep", ".hidden"], ["keep.txt", ".hidden.txt"])]
        ),
    )

    def source(_self):
        yield "header"
        yield next(cmd_view._filtered_walklevel(root, 2))
        yield "tail"

    monkeypatch.setattr(cmd_view, "_load_bit_by_bit", source)
    result = list(cmd_view._filtered_load_bit_by_bit(directory))
    assert result[0] == "header"
    assert result[1] == (root, ["keep"], ["keep.txt"])
    assert result[2] == "tail"
    assert cmd_view._flat_context.value is None
