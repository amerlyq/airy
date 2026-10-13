"""cmd_xfer: moving/linking selection around: mvsel, link_orig, paste_relink, paste_flatlink.

## CONFLICT(vdsym-split / pasteflow): memory says paste override plugin will own :paste/:paste_symlink
##   and "jump to first pasted". paste_relink/paste_flatlink bypass :paste entirely (os.symlink on
##   fm.copy_buffer) => they will NOT jump. ALT: route them through pasteflow once it exists.
##   rc.conf `pp` (jump-after-paste lambda) is deliberately NOT ported: superseded by pasteflow.
## MAPS: `m<any>`/`F`/`D` mvsel | `Y` link_orig | `ps` paste_relink | `py` paste_flatlink
## ALT: rc.conf `gy` (shell ln -svt %D) is the dumb version of link_orig -- left in rc.conf
"""

from __future__ import annotations

import os
from os import path as fs

from ranger.api.commands import Command


class mvsel(Command):
    """:mvsel %any_path

    Move files from current selection to dir on cmdline (OR one of bookmarks)
    """

    def execute(self) -> None:
        dest = self.rest(1)
        self.fm.cut()
        self.fm.paste(dest=dest)
        self.fm.notify(dest)


class link_orig(Command):
    def execute(self) -> None:
        d: str = self.fm.get_macros()["D"]

        def linkedpath(p: str) -> str:
            if fs.islink(p):
                return fs.abspath(fs.join(fs.dirname(p), os.readlink(p)))
            parent: str = fs.dirname(p)
            if fs.islink(parent):
                # OR:(one level only):
                # parent = fs.abspath(fs.join(fs.dirname(parent), os.readlink(parent))) if fs.islink(parent) else parent
                parent = fs.realpath(parent)
                return fs.join(parent, fs.basename(p))
            return fs.abspath(p)

        def optrelpath(c: str) -> str:
            return fs.relpath(c, d) if fs.commonpath([d, c]) == fs.abspath(d) else c

        failed = 0
        duplicate = 0
        for f in self.fm.thistab.get_selection():
            src: str = linkedpath(f.path)
            target: str = fs.join(d, fs.basename(src))
            if fs.abspath(src) == fs.abspath(target):
                continue
            if fs.islink(target) and fs.realpath(target) == fs.realpath(src):
                duplicate += 1
                continue
            self.fm.execute_command(
                f'ln -svt "{d}" --backup=numbered -- "{optrelpath(src)}"'
            )
            # MAYBE: notify user if some links had failed (e.g. wrong relative path)
            if not fs.exists(target):
                failed += 1

        self.fm.mark_files(all=True, val=False)
        if duplicate:
            note = (
                "symlink with same target already exists"
                if duplicate == 1
                else f"{duplicate} symlinks with same target already exist"
            )
            self.fm.notify(note, bad=bool(failed))
        else:
            self.fm.notify("Copied to -> " + d, bad=bool(failed))


# HACK:(annex): insert symlinks with fixed object path
# %ONELINE: map ps eval for l in fm.copy_buffer: os.symlink(fm.fs.relpath(fm.fs.join(l.dirname, os.readlink(l.path)), start=fm.thistab.path), fm.fs.join(fm.thistab.path, l.basename))
class paste_relink(Command):
    """:paste_relink -- re-create symlinks of copy_buffer here, target re-expressed relative to cwd"""

    def execute(self) -> None:
        fm = self.fm
        dst = fm.thistab.path
        try:
            for l in fm.copy_buffer:
                tgt = fs.join(l.dirname, os.readlink(l.path))
                os.symlink(fs.relpath(tgt, start=dst), fs.join(dst, l.basename))
        except OSError as e:
            fm.notify(f"paste_relink: {e}", bad=True)


# %ONELINE: map py eval for l in fm.copy_buffer: os.symlink(l.path, fm.fs.join(fm.thistab.path, l.path.replace("/", "⁄")))
class paste_flatlink(Command):
    """:paste_flatlink -- symlink copy_buffer items here, named by full path with "/" -> U+2044 "⁄" """

    def execute(self) -> None:
        fm = self.fm
        dst = fm.thistab.path
        try:
            for l in fm.copy_buffer:
                os.symlink(l.path, fs.join(dst, l.path.replace("/", "⁄")))
        except OSError as e:
            fm.notify(f"paste_flatlink: {e}", bad=True)
