"""Guard Ranger's command loader against late preview output after its select loop.

Some Ranger versions leave `read_stdout` as None when the child exits before select reads
its pipe, then append the final pipe read to None. Patch only that exact upstream expression;
leave versions with a different implementation untouched.
"""

from __future__ import annotations

import inspect
import logging
import textwrap

from ranger.core.loader import CommandLoader

try:
    import rhooks
except ImportError:
    from plugins import rhooks

_LOG = logging.getLogger("ranger.loader_stdout_fix")
_LATE_READ = "read_stdout += read"


def _make_generate(original):
    try:
        source = textwrap.dedent(inspect.getsource(original))
    except (OSError, TypeError):
        _LOG.warning(
            "could not inspect Ranger CommandLoader.generate; leaving unchanged"
        )
        return original

    if source.count(_LATE_READ) != 1:
        return original

    namespace = dict(original.__globals__)
    patched_source = source.replace(
        _LATE_READ,
        "read_stdout = (read_stdout or b'') + read",
        1,
    )
    try:
        exec(compile(patched_source, original.__code__.co_filename, "exec"), namespace)
    except (SyntaxError, TypeError):
        _LOG.exception(
            "could not patch Ranger CommandLoader.generate; leaving unchanged"
        )
        return original
    return namespace[original.__name__]


rhooks.patch(CommandLoader, "generate", _make_generate)
