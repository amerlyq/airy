"""xattr line mode decodes lsattr output and handles unsupported filesystems."""

from subprocess import CalledProcessError
import pytest
from plugins.xattr_linemode import XAttrLinemode


def test_xattr_decodes_lsattr_output(monkeypatch):
    monkeypatch.setattr(
        "subprocess.check_output", lambda *a: b"----i--------e------- file\n"
    )
    assert XAttrLinemode().xattr_get("file") == "----i--------e-------"


def test_xattr_translates_command_failure_to_not_implemented(monkeypatch):
    monkeypatch.setattr(
        "subprocess.check_output",
        lambda *a: (_ for _ in ()).throw(CalledProcessError(1, "lsattr")),
    )
    with pytest.raises(NotImplementedError):
        XAttrLinemode().xattr_get("file")
