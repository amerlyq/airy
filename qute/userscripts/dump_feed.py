#!/usr/bin/env python3
# ALT: $ qutebrowser ':debug-dump-page /t/page'
import os
from pathlib import Path
from urllib.parse import urlsplit

from just.web.src.mangatx import summary


def qute_send(cmdline: str) -> None:
    with open(os.environ["QUTE_FIFO"], "w", encoding="utf-8") as f:
        f.write(cmdline)


def main() -> None:
    host = urlsplit(os.environ["QUTE_URL"]).hostname  # .rpartition(".")[0]
    src = Path(os.environ["QUTE_HTML"])
    dst = Path(f"/t/{host}.nou")

    page = Path(f"/t/{host}.html")
    page.write_text(src.read_text(encoding="utf-8"))

    try:
        prgs = list(summary(src))
    except Exception as exc:
        dst.write_text(str(exc), encoding="utf-8")
        qute_send("message-info '{}'".format(f"Exception! See {dst}"))
    else:
        progress = "\n".join(reversed(sorted(prgs)))
        dst.write_text(progress, encoding="utf-8")
        qute_send("message-info '{}'".format(f"Comics progress dumped to {dst}"))


if __name__ == "__main__":
    main()
