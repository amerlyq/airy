"""Overview movement preserves the standard movement path when disabled."""

from types import SimpleNamespace
from plugins import overview


def test_disabled_overview_move_delegates_to_ranger_move():
    calls = []
    command = overview.overview_move("overview_move down")
    command.fm = SimpleNamespace(move=lambda **kw: calls.append(kw))
    command.execute()
    assert calls == [{"down": 1}]


def test_overview_toggle_reports_state(monkeypatch):
    notices = []
    fm = SimpleNamespace(notify=notices.append)
    command = overview.overview_toggle("overview_toggle")
    command.fm = fm
    command.execute()
    command.execute()
    assert notices == ["overview on", "overview off"]
