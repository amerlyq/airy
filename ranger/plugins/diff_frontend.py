import os
import shlex

from ranger.api.commands import Command

# DEV: df cidx!=tidx: search file with same name in tidx
#   -- if no such file == show error
#   BUT: then can't compare different names in tabs fast
#       -- 'cause need to 'vsel' them before compare
# DEV: df multiselection to multiselection
#   => treat like dirs %d %D compare with only selected files
# DEV: substitute python-like placeholders -> {}, {1}, {2}
#   else -> append filelist

## MAYBE:(impossible?)
#  ALT: arg to ':map' to specify right column text
#  ALT: embed comment into command, likewise 'map key cmd  # desc'
#  ALT:TRY: filter-out '\s*#\s.*$' from ':df' arguments to simulate per-map comments
## USAGE:  :df [-FLAGS] CMD [ARGS...]   -- FLAGS = ranger `:shell` flags (w, p, ...)
#   quantifier N (`3dfd`) = compare with tab number N, else next tab
# map dfb df -w binwalk -WiU
# map dfc df -w cmp -l
# map dfd df -w diff -rU0
# map dfD df -w diff -rwEZB
# map dfe df -w delta
# map dfg df -w git diff --no-index --
# map dfG df -w git diff --no-index --stat --
# map dfh df dhex
# map dfr df -w r.diff-fs
# map dfR df -w r.diff-fs -d
# map dfs df -w rsync -av --out-format=%%i|%%f --delete --dry-run --
# map dft df -w difft
# map dfz df -w r.diff-fs -s
# map dfZ df -w r.diff-fs -S
# map dfu df -w diff -rU5
# map dfv df nvim -d
# map dfV df nvim -c 'exe"DirDiff\x20".join(argv())' --

CMP_LIMIT = 30  # `cmp -l`: print byte list only if fewer lines than this
# tools whose exit code means 0=same 1=differs >1=error
# (others, e.g. nvim/delta/dhex/rsync, would show a bogus verdict)
VERDICT = frozenset({"cmp", "diff", "git"})

# $1=cmp -l line limit ('' = off)  $2=filesize  rest=command
_WRAP = r"""
lim=$1 size=$2; shift 2
if [ -n "$lim" ]; then
  "$@" | awk -v lim="$lim" -v size="$size" '
    NR < lim { buf[NR] = $0 }
    END {
      if (NR < lim) for (i = 1; i <= NR; i++) print buf[i]
      else printf "%d / %d bytes differ (%.2f%%), list suppressed (>= %d lines)\n",
                  NR, size, size > 0 ? 100 * NR / size : 0, lim
    }'
  rc=${PIPESTATUS[0]}
else
  "$@"; rc=$?
fi
case $rc in
  0) printf '\033[1;32msame\033[m\n' ;;
  1) printf '\033[1;31mdiffers\033[m\n' ;;
  *) printf '\033[1;33merror\033[m rc=%d\n' "$rc" ;;
esac
exit "$rc"
"""


def _is_cmp_list(cmd: list[str]) -> bool:
    return cmd[0] == "cmp" and any(
        a == "--verbose" or (a[:1] == "-" and a[1:2] != "-" and "l" in a)
        for a in cmd[1:]
    )


def _pick(cur, tgt, cross: bool):
    """-> two files to compare, else ValueError(msg)"""
    cm, tm = cur.thisdir.marked_items, tgt.thisdir.marked_items
    if cross and not cm and not tm:
        return [cur.thisfile, tgt.thisfile]
    if not cross or not tm:
        match cm:
            case [a]:  # gliding diff: marked vs cursor
                return [a, cur.thisfile]
            case [_, _]:
                return list(cm)
        raise ValueError("curr_tab: select one or two files")
    if not cm and len(tm) == 1:
        return [cur.thisfile, tm[0]]
    if len(cm) == 1 and len(tm) == 1:
        return [cm[0], tm[0]]
    raise ValueError("incompatible selection")


class df(Command):
    def execute(self) -> int | None:  # pyright: ignore[reportIncompatibleMethodOverride]
        fm = self.fm
        flags = ""
        if self.arg(1).startswith("-"):
            flags = self.arg(1).lstrip("-")
            self.shift()
        try:
            cmd = shlex.split(self.rest(1))
        except ValueError as e:
            return self._err(f"bad quoting: {e}")
        if not cmd:
            return self._err("no command")

        keys = sorted(fm.tabs)
        cur = fm.current_tab
        tgt = (
            self.quantifier
            if self.quantifier is not None
            else keys[(keys.index(cur) + 1) % len(keys)]
        )
        if tgt not in fm.tabs:
            return self._err(f"no tab {tgt}")

        try:
            fls = _pick(fm.tabs[cur], fm.tabs[tgt], cross=cur != tgt)
        except ValueError as e:
            return self._err(str(e))
        if None in fls:
            return self._err("empty dir: no file under cursor")
        if fls[0].path == fls[1].path:
            return self._err("refuse to compare the same file")

        # DEV: substitute python-like placeholders -> {}, {1}, {2}
        cmd += [f.path + ("/" if f.is_directory else "") for f in fls]

        if os.path.basename(cmd[0]) in VERDICT:
            lim = ""
            size = 0
            if _is_cmp_list(cmd):
                lim = str(CMP_LIMIT)
                size = max(os.path.getsize(f.path) for f in fls)
            cmd = ["bash", "-c", _WRAP, "bash", lim, str(size), *cmd]
        fm.execute_command(cmd, flags=flags)
        return None

    def _err(self, msg: str) -> int:
        self.fm.notify(f"df: {msg}", bad=True)
        return 1
