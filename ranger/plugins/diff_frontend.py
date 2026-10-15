import os
import shlex

from collections.abc import Callable

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
##   `%1` / `%2` substitute selected paths; absent placeholders append both.
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


FALLBACKS: dict[str, Callable] = {}
FRONTEND_FLAGS = {"m": "same", "M": "other"}
FALLBACK_FLAGS = {"F": "duration"}


def _duration_next(cur, tgt, cross, current, target):
    """Advance to the next member of each current duration group."""
    try:
        from plugins.vddur_sort_linemode import duration_groups
    except ImportError:
        return None

    def next_in_group(directory, origin):
        group = next(
            (
                group
                for group in duration_groups(directory.files_all or [])
                if any(f.path == origin.path for f in group)
            ),
            (),
        )
        index = next((i for i, file in enumerate(group) if file.path == origin.path), -1)
        if index < 0 or len(group) < 2:
            return None
        return group[index - 1] if index else group[1]

    if current is None:
        return None
    left = next_in_group(cur.thisdir, current)
    if not cross:
        return [current, left] if left else None
    right = next_in_group(tgt.thisdir, target) if target is not None else None
    return [left or current, right or target] if left or right else None


FALLBACKS["duration"] = _duration_next


def _pick(cur, tgt, cross: bool, policy: str | None = None, fallback: str | None = None):
    """-> two files to compare, else ValueError(msg)"""
    if policy == "same" and cross:
        raise ValueError("comparison requires current tab")
    if policy == "other" and not cross:
        raise ValueError("comparison requires another tab")
    no_selection = False
    try:
        picked = _pick_selection(cur, tgt, cross)
    except ValueError as exc:
        no_selection = str(exc) == "curr_tab: select one or two files"
        picked = None
    if picked and None in picked:
        no_selection = True
        picked = None
    if picked is None and fallback and no_selection:
        resolver = FALLBACKS.get(fallback)
        if resolver is None:
            raise ValueError(f"unknown fallback {fallback}")
        picked = resolver(cur, tgt, cross, cur.thisfile, tgt.thisfile if cross else None)
    if picked is not None:
        return picked
    if picked is None and fallback and no_selection:
        raise ValueError(f"no {fallback} fallback candidate")
    return _pick_selection(cur, tgt, cross)


def _pick_selection(cur, tgt, cross: bool):
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
        policy = None
        fallback = None
        if self.arg(1).startswith("-"):
            raw = self.arg(1).lstrip("-")
            flags = "".join(ch for ch in raw if ch not in FRONTEND_FLAGS and ch not in FALLBACK_FLAGS)
            policies = {FRONTEND_FLAGS[ch] for ch in raw if ch in FRONTEND_FLAGS}
            fallbacks = {FALLBACK_FLAGS[ch] for ch in raw if ch in FALLBACK_FLAGS}
            if len(policies) > 1 or len(fallbacks) > 1:
                return self._err("conflicting frontend flags")
            policy = next(iter(policies), None)
            fallback = next(iter(fallbacks), None)
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
        if policy == "same" and self.quantifier is None:
            tgt = cur
        if tgt not in fm.tabs:
            return self._err(f"no tab {tgt}")

        try:
            fls = _pick(
                fm.tabs[cur], fm.tabs[tgt], cross=cur != tgt,
                policy=policy, fallback=fallback,
            )
        except ValueError as e:
            return self._err(str(e))
        if None in fls:
            return self._err("empty dir: no file under cursor")
        if fls[0].path == fls[1].path:
            return self._err("refuse to compare the same file")

        paths = [f.path + ("/" if f.is_directory else "") for f in fls]
        has_placeholders = any("%1" in arg or "%2" in arg for arg in cmd)
        if has_placeholders:
            # ALT: substitute python-like placeholders -> {}, {1}, {2}
            cmd = [arg.replace("%1", paths[0]).replace("%2", paths[1]) for arg in cmd]
        else:
            cmd += paths

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
