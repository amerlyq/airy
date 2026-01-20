from airy.api import ln

# DEPR: https://bugs.archlinux.org/task/68945
# ln("cfg/pam_environment", file="~/.pam_environment")
ln("cfg/profile", under="/etc")


def ab(src: str, file: str = None, **kw: str) -> ln:
    return ln(src, file=file, **kw, under="/usr/local/bin")  # ALT: /b


ab("/d/airy/qute/ctl/proxy", "bw")
ab("qutebrowser", "b", at="/usr/bin")

ab("nvim", "v", at="/usr/bin")
ab("nvim", "vim", at="/usr/bin")
ab("/d/airy/vim/ctl/qf", "vq")

ab("/usr/bin/ranger", ",s")
ab("/usr/bin/ranger", "fm")

# %USAGE: $ diff -u A B | diff-so-fancy
ab("/usr/bin/diff-so-fancy", "dfc")

ab("/d/airy/grep/ctl/repo", "re")
ab("/d/airy/grep/ctl/ia", "rs")

ab("/d/just/ctl", "j")
ab("/d/just/ctl", "just")

ab("/d/airy/hpx/scr/rot")
ab("/d/airy/init/bin/xcv")
ab("/d/airy/open/bin/man")
ab("/d/airy/open/bin/actualee")

ab("xc", at="/d/airy/xsel/bin")
ab("xci", at="/d/airy/xsel/bin")
ab("xcio", at="/d/airy/xsel/bin")
ab("xco", at="/d/airy/xsel/bin")
ab("xcx", at="/d/airy/xsel/bin")
