# FEAT: `:zs [flags] <cmd>` = `:shell` + aliases only (no .zshrc, plugins, compinit)
# WHY: `:shell` -> non-interactive `zsh -c` -> .zshrc not read -> no aliases
# WHY eval: aliases expand at PARSE time; `source X; alias_cmd` in one -c string
#   is parsed before X runs -> eval re-parses AFTER sourcing
# WHY-NOT override `shell`: would copy its flag/macro parsing -> drifts on upgrade
# TROUBLESHOOT:
#   alias not found  -> `:zs alias` to list what was loaded; check ALIAS_FILES paths
#   `s` still stock  -> mapping order, see MAP below
#   alias uses a function from .zshrc -> unsupported by design, source it in ALIAS_FILES
# EXTEND: add files to ALIAS_FILES; swap "zsh" for $SHELL; add `-l` for login env
import re
import shlex

from ranger.api.commands import Command

# NOTE: same list/order as the old .zshrc block; order matters (later overrides earlier)
ALIAS_FILES = (
    "/d/airy/zsh/arc/alias/aliases",
    "/d/airy/zsh/cfg/aliases_git",
    "/d/airy/zsh/cfg/aliases",
    "/d/airy/ssh/alias",
)

# NOTE: $1 = user command; `.` = source; missing file is skipped silently (-r guard)
_SCRIPT = (
    "for f in " + " ".join(shlex.quote(p) for p in ALIAS_FILES) + "; do "
    '[[ -r $f ]] && . $f; done; eval "$1"'
)

# NOTE: leading `:shell` flags (-p, -w, -f, -s, -c, -t...) forwarded untouched
_FLAGS = re.compile(r"^(-\w+\s+)*")


class zs(Command):
    def execute(self):
        rest = self.rest(1)
        if not rest:
            return
        flags = _FLAGS.match(rest).group(0)
        cmd = rest[len(flags) :]
        # NOTE: %f/%s macros survive shlex.quote, expanded later by `shell`
        self.fm.execute_console(
            "shell %szsh -c %s zsh %s" % (flags, shlex.quote(_SCRIPT), shlex.quote(cmd))
        )

    def tab(self, tabnum):
        return self._tab_directory_content()  # stock path completion
