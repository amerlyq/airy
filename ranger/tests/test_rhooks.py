"""Idempotent Ranger hooks shared by plugins."""

from types import SimpleNamespace

from plugins import rhooks


def test_shared_state_is_created_once_and_survives_module_reexecution():
    key = "pytest.shared-state"
    rhooks._S.__dict__.pop(key, None)
    state = rhooks.shared(key, list)

    assert rhooks.shared(key, lambda: ["wrong"]) is state


def test_patch_wraps_the_original_once_even_after_re_registration():
    class Owner:
        def method(self, value):
            return value + 1

    def wrapper(original):
        return lambda self, value: original(self, value) * 2

    rhooks.patch(Owner, "method", wrapper)
    first = Owner.method
    rhooks.patch(Owner, "method", wrapper)

    assert Owner.method is not first
    assert Owner().method(2) == 6
    assert rhooks.shared("orig", dict)[(Owner, "method")](Owner(), 2) == 3


def test_cd_dispatch_isolates_handler_errors_and_continues():
    calls = []
    original = rhooks._S.cd
    rhooks._S.cd = {
        "broken": lambda _path: (_ for _ in ()).throw(RuntimeError("expected")),
        "good": calls.append,
    }
    try:
        rhooks._dispatch_cd(SimpleNamespace(new=SimpleNamespace(path="/tmp/new")))
    finally:
        rhooks._S.cd = original

    assert calls == ["/tmp/new"]


def test_tick_wrapper_preserves_loader_result_and_runs_registered_callbacks():
    calls = []
    original = rhooks._S.tick
    rhooks._S.tick = {"first": lambda: calls.append("first")}
    try:
        result = rhooks._make_work(lambda self, value: value + 1)(object(), 4)
    finally:
        rhooks._S.tick = original

    assert result == 5
    assert calls == ["first"]
