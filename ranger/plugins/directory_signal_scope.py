"""Avoid directory callbacks for setlocal/setinregex changes elsewhere."""

from functools import lru_cache
import re

from ranger.container.directory import Directory


@lru_cache(maxsize=256)
def _compile(pattern):
    try:
        return re.compile(pattern)
    except re.error:
        return None


def _signal_function_factory(self, function):
    def signal_function(signal=None):
        # Local settings carry their regex in signal.path. Ranger's stock
        # callback ignores it, so every loaded Directory sorts/refilters.
        if signal is not None and signal.path:
            regex = _compile(signal.path)
            if regex is None or not regex.search(self.path):
                return
        self.load_if_outdated()
        if self.exists:
            function()

    return signal_function


Directory.signal_function_factory = _signal_function_factory
