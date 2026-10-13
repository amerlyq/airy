"""cmd_avfs: `h`/`l` that step into/out of archives through the AVFS mount (`<archive>#/`).

## USAGE: map h avfs_left | map l avfs_right     (fall back to plain move left/right)
## ARCH: archive file under cursor -> cd `$XDG_RUNTIME_DIR/avfs/<abs path>#/`; `h` inside returns to the archive file
## NOTE: AVFSDIR duplicates rc.conf `eval ... fm.avfsdir=...` (kept there: `setlocal path={fm.avfsdir}` needs it
##   at rc-source time; probably hook_init runs earlier than rc.conf but unverified). MAYBE: unify later.
## DEBUG: ls $XDG_RUNTIME_DIR/avfs ; :eval fm.avfsdir
"""

### HACK: explore inside archives SEE:(avfs):※⡠⡟⠗⡌
## auto-explore archives SRC: https://github.com/ranger/ranger/issues/2164
# [⡠⡏⢁⡶] FIXED: move parent.cursor in fm.avfsdir to reflect the same position as in original archive dir
# [_] TODO: prevent diving recursively into same archive -- FUSE freezes in that case
#   FIXED:(in case of FUSE freeze e.g. open archive again being already in avfsdir): $ echo 1 | sudo tee -a /sys/fs/fuse/connections/XXX/abort
# FIXED:(prevent freeze): (<) don't allow recursive archives (<) don't allow any archives under fm.avfsdir
#   [?] ALSO: on <S-j> exit from /run instead of jumping to nearest parent in /run

from __future__ import annotations

import os

from ranger.api.commands import Command

AVFSDIR = os.path.join(os.getenv("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}"), "avfs")
ARCH_EXT = frozenset(
    {"zst", "zstd", "lz", "apk"}
)  # not flagged as `container` by ranger


# %ONELINE:
# eval import os.path as fs; fm.fs=fs; fm.avfsdir=fs.join(os.getenv('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}'), 'avfs')
# eval cmd(f'setlocal path={fm.avfsdir} preview_files false')  # WARN: fragile, no escaping on expansion
# map h eval (lambda x: fm.select_file(x.removeprefix(fm.avfsdir)) if (fm.fs.isdir(fm.avfsdir) and x.startswith(fm.avfsdir) and fm.fs.isfile(x)) else fm.move(left=1))(fm.thisdir.path.removesuffix('#'))
# map l eval (lambda x, z: (fm.select_file(f'{z}'), fm.cd(f'{z}#/')) if (fm.fs.isdir(fm.avfsdir) and x.is_file and not x.path.startswith(fm.avfsdir) and (x.container or x.extension in ['zst', 'zstd', 'lz', 'apk'])) else fm.move(right=1))(fm.thisfile, fm.avfsdir + fm.thisfile.path.removeprefix(fm.avfsdir))


class avfs_left(Command):
    def execute(self) -> None:
        fm = self.fm
        p = fm.thisdir.path.removesuffix("#")
        if os.path.isdir(AVFSDIR) and p.startswith(AVFSDIR) and os.path.isfile(p):
            fm.select_file(p.removeprefix(AVFSDIR))
        else:
            fm.move(left=1)


class avfs_right(Command):
    def execute(self) -> None:
        fm = self.fm
        f = fm.thisfile
        if (
            f is not None
            and os.path.isdir(AVFSDIR)
            and f.is_file
            and not f.path.startswith(AVFSDIR)
            and (f.container or f.extension in ARCH_EXT)
        ):
            z = AVFSDIR + f.path.removeprefix(AVFSDIR)
            fm.select_file(z)
            fm.cd(f"{z}#/")
        else:
            fm.move(right=1)
