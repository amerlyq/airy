"""rutil: shared helpers for cmd_*.py plugins (no commands, no side effects).

## ARCH: ranger imports plugins as `plugins.<name>` (see vddur_sort_linemode.py: `from plugins import vdprobe`)
##   => siblings do `from plugins.rutil import ...`
## WHY: today_date()/tmpfile() were used by several former commands.py classes (doc, cda, cd_shelldir, actualee)
##   -> one home instead of copies; Protocols are typing-only (pyright), zero runtime cost
## EXT: put here only what 2+ plugins need. Anything single-use stays in its plugin.
"""

from __future__ import annotations

import os
from collections.abc import Iterable, Sequence
from os import path as fs
from re import Pattern
from typing import Protocol, TypeAlias

CompletionResult: TypeAlias = str | Iterable[str] | None


class DirectoryEntry(Protocol):
    """The filesystem-object surface needed by recursive filtering."""

    is_directory: bool


class FilterableDirectory(Protocol):
    """The directory surface used by ``ag._filter`` and ``unfilter``."""

    filter: object | None
    temporary_filter: Pattern[str] | None
    files_all: Sequence[DirectoryEntry] | None

    def refilter(self) -> None: ...


# NOTE: jump to next day only at 7:00AM
def today_date(delta: int = 7) -> str:
    import datetime

    return (
        datetime.datetime.now(datetime.timezone.utc).astimezone()
        - datetime.timedelta(hours=delta)
    ).strftime("%Y-%m-%d")


# BAD: ranger crash on exit if '--choosedir' path was deleted by 3rd party
def tmpfile(nm: str) -> str:
    ge = os.getenv
    tmp = ge(
        "RANGER_TMPDIR",
        # ALT: fs.join(ge("TMPDIR", fs.join("/tmp", ge("USER", ""), "ranger"))),
        fs.join(ge("XDG_RUNTIME_DIR", "/tmp"), "ranger"),
    )
    if not fs.isdir(tmp):
        os.mkdir(tmp)
    return fs.join(tmp, nm)
