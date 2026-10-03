import re
import subprocess

from ranger.api.commands import Command

BASE = {
    "path": lambda fm: fm.thisfile.path,
    "dir": lambda fm: fm.thisdir.path,
    "name": lambda fm: fm.thisfile.relative_path,
    "sel": lambda fm: "\n".join(f.relative_path for f in fm.thistab.get_selection()),
}

# aliases: same syntax as the command arg
ALIAS = {
    "dot": "regex=\\..*",
    "dash": "glob='-*'",
    "under": "glob='_*'",
    "head": "regex='[/／⁄].*'",
    "tail": "regex='.*[/／⁄]'",
    "d0": "split='-',0",
    "d1": "split='-',1",
    "d2": "split='-',2",
    "dl": "split='-',-1",
}


def _unquote(s):  # no backslash processing, unlike shlex
    return s[1:-1] if len(s) >= 2 and s[0] == s[-1] and s[0] in "'\"" else s


def _glob(p):  # only * and ? are special
    return re.escape(p).replace(r"\*", ".*").replace(r"\?", ".")


def _split(arg, name):  # SEP,IDX  |  SEP,A:B
    sep, _, idx = arg.rpartition(",")
    sep = _unquote(sep)
    parts = name.split(sep)
    if ":" in idx:
        s = slice(*(int(x) if x else None for x in idx.split(":")))
        return sep.join(parts[s])
    return parts[int(idx)]


class yank_as(Command):
    """:yank_as {path|dir|name|sel|ALIAS} | glob=PAT | regex=PAT | split=SEP,IDX
    PAT/SEP may be '...' or "..." quoted.
    glob=/regex= delete the first match from the name.
    split= picks a piece (IDX) or slice (A:B) of name.split(SEP), Python semantics."""

    def execute(self):
        arg = self.rest(1).strip()
        arg = ALIAS.get(arg, arg)
        fm = self.fm
        name = fm.thisfile.relative_path
        kind, _, pat = arg.partition("=")
        if kind == "split":
            text = _split(pat, name)
        elif kind in ("glob", "regex"):
            pat = _unquote(pat)
            rx = _glob(pat) if kind == "glob" else pat
            text = re.sub(rx, "", name, count=1)
        else:
            text = BASE[arg](fm)
        subprocess.run(
            ["xci"], input=text.encode(), stdout=subprocess.DEVNULL, check=True
        )
