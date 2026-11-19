"""Clipboard hook API, command failures, quoting, and writes."""

from types import SimpleNamespace

from plugins import clipboard


def test_hook_installs_get_set_helpers_and_reports_failed_commands(monkeypatch):
    fm = SimpleNamespace(notify=lambda exc, **kw: setattr(fm, "notice", (exc, kw)))
    monkeypatch.setattr(clipboard, "old_hook_init", lambda _fm: None)
    outputs = iter(
        [
            SimpleNamespace(stdout=b"a path\n"),
            SimpleNamespace(stdout=b"a path\n"),
            SimpleNamespace(stdout=b"ignored"),
        ]
    )
    calls = []

    def run(**kw):
        calls.append(kw.copy())
        return next(outputs)

    monkeypatch.setattr(clipboard, "run", run)
    clipboard.hook_init(fm)
    assert fm.get_clipboard() == "a path"
    assert fm.get_clipboard_q() == "'a path'"
    assert fm.set_clipboard("hello") == ""
    assert calls[0] == {"args": ["xco"], "check": True, "stdout": clipboard.PIPE}
    assert calls[1] == {"args": ["xco"], "check": True, "stdout": clipboard.PIPE}
    assert calls[2] == {
        "args": ["xci"],
        "input": "hello",
        "stdout": None,
        "check": True,
    }
    assert not hasattr(fm, "notice")


def test_clipboard_failure_returns_empty_and_notifies(monkeypatch):
    from subprocess import CalledProcessError

    notices = []
    fm = SimpleNamespace(notify=lambda *a, **kw: notices.append((a, kw)))
    monkeypatch.setattr(clipboard, "old_hook_init", lambda _fm: None)
    monkeypatch.setattr(
        clipboard,
        "run",
        lambda **kw: (_ for _ in ()).throw(CalledProcessError(1, "xco")),
    )
    clipboard.hook_init(fm)
    assert fm.get_clipboard() == ""
    assert notices and notices[0][1]["bad"] is True
