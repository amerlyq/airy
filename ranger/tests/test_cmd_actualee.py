"""Actualee command rotates listing at the cursor and handles executables."""

from types import SimpleNamespace
from plugins.cmd_actualee import actualee


def test_actualee_writes_cursor_first_listing_and_arguments(tmp_path, monkeypatch):
    monkeypatch.setattr(actualee, "FLST", str(tmp_path / "buffer"))
    entries = [SimpleNamespace(path=p) for p in ("/a", "/b", "/c")]
    calls = []
    fm = SimpleNamespace(
        thisfile=SimpleNamespace(
            path="/b", is_file=True, get_permission_string=lambda: "rw-"
        ),
        thisdir=SimpleNamespace(files=entries),
        execute_command=calls.append,
    )
    command = actualee("actualee --flag")
    command.fm = fm
    command.execute()
    assert (tmp_path / "buffer").read_text() == "/b\n/c\n/a"
    assert calls == [["actualee", "--flag", "-l", "/b", str(tmp_path / "buffer")]]


def test_executable_cursor_runs_directly_without_listing():
    calls = []
    file = SimpleNamespace(
        path="/bin/tool", is_file=True, get_permission_string=lambda: "rwxr-xr-x"
    )
    command = actualee("actualee")
    command.fm = SimpleNamespace(thisfile=file, execute_command=calls.append)
    command.execute()
    assert calls == ["/bin/tool"]
