"""Guarded patch only changes the known late stdout append expression."""

from plugins import ranger_loader_stdout_fix as fix


def test_patch_factory_changes_only_the_known_expression(monkeypatch):
    def original():
        read_stdout = None
        read = b"tail"
        read_stdout += read
        return read_stdout

    monkeypatch.setattr(
        fix.inspect,
        "getsource",
        lambda _: (
            "def original():\n    read_stdout = None\n    read = b'tail'\n    read_stdout += read\n    return read_stdout\n"
        ),
    )
    patched = fix._make_generate(original)
    assert patched is not original
    assert patched() == b"tail"


def test_unrecognized_source_is_left_unchanged(monkeypatch):
    def original():
        return b"safe"

    monkeypatch.setattr(
        fix.inspect, "getsource", lambda _: "def original(): return b'safe'\n"
    )
    assert fix._make_generate(original) is original
