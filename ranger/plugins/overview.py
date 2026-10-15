"""Opt-in j/k traversal across sibling directory contents."""

from ranger.api.commands import Command

_enabled = False


def _step(fm, direction):
    directory = fm.thisdir
    files = directory.files or []
    if not files or (direction > 0 and directory.pointer != len(files) - 1) or (
        direction < 0 and directory.pointer != 0
    ):
        fm.move(down=direction)
        return

    parent = fm.thistab.at_level(-1)
    siblings = parent.files if parent is not None else None
    if not siblings:
        fm.move(down=direction)
        return
    index = next((i for i, item in enumerate(siblings) if item.path == directory.path), None)
    if index is None:
        fm.move(down=direction)
        return

    for sibling in siblings[index + direction :: direction]:
        if direction < 0 and sibling.path == directory.path:
            continue
        if not sibling.is_directory:
            continue
        target = fm.get_directory(sibling.path)
        target.load_content(schedule=False)
        if not target.files:
            continue
        fm.enter_dir(target.path)
        fm.thisdir.move(to=0 if direction > 0 else -1)
        return
    # At the outermost sibling, stay on this directory's boundary.


class overview_move(Command):
    def execute(self):
        direction = 1 if self.arg(1).startswith("down") else -1
        count = self.quantifier or 1
        for _ in range(count):
            if _enabled:
                _step(self.fm, direction)
            else:
                self.fm.move(down=direction)


class overview_toggle(Command):
    def execute(self):
        global _enabled
        _enabled = not _enabled
        state = "on" if _enabled else "off"
        self.fm.notify(f"overview {state}")
