"""The %date macro uses the current local calendar date."""

import time

from plugins import macro_date


def test_date_macro_preserves_other_macros_and_expands_date(monkeypatch):
    monkeypatch.setattr(macro_date, "GET_MACROS_OLD", lambda _self: {"path": "/tmp"})
    macros = macro_date.get_macros_with_date(None)
    assert macros["path"] == "/tmp"
    assert macros["dt"] == time.strftime("%Y%m%d")
    assert macros["dT"] == time.strftime("%Y-%m-%d")
    assert macros["dw"] == time.strftime("%Y-%m-%d-%a")
    assert macros["date"] == time.strftime("%Y/%m/%d")
