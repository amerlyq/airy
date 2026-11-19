"""Scoped and cached callback dispatch for directory-local Ranger settings."""

from types import SimpleNamespace

from plugins import directory_signal_scope as scope


def test_regex_compilation_is_cached_and_invalid_patterns_are_safe():
    scope._compile.cache_clear()
    first = scope._compile("/media/.+")
    assert first is scope._compile("/media/.+")
    assert scope._compile("[") is None


def test_local_signal_only_calls_directory_callback_for_matching_path():
    calls = []
    directory = SimpleNamespace(
        path="/media/videos",
        exists=True,
        load_if_outdated=lambda: calls.append("load"),
    )
    callback = scope._signal_function_factory(
        directory, lambda: calls.append("callback")
    )

    callback(SimpleNamespace(path="/media/photos"))
    assert calls == []
    callback(SimpleNamespace(path="/media/.+"))
    assert calls == ["load", "callback"]


def test_missing_signal_path_preserves_global_callback_behavior():
    calls = []
    directory = SimpleNamespace(
        path="/media/videos",
        exists=False,
        load_if_outdated=lambda: calls.append("load"),
    )
    scope._signal_function_factory(directory, lambda: calls.append("callback"))(
        SimpleNamespace(path="")
    )
    assert calls == ["load"]
