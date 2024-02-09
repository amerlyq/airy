from airy.api import ln

# DEPR: https://bugs.archlinux.org/task/68945
# ln("cfg/pam_environment", file="~/.pam_environment")
ln("cfg/profile", under="/etc")


def ab(src: str, file: str = None, **kw: str) -> ln:
    return ln(src, file=file, **kw, under="/usr/local/bin")


ab("/@/airy/qute/ctl/proxy", "bw")
ab("qutebrowser", "b", at="/usr/bin")

ab("nvim", "v", at="/usr/bin")
ab("nvim", "vim", at="/usr/bin")
ab("/@/airy/vim/ctl/qf", "vq")

ab("/usr/bin/ranger", ",s")
ab("/usr/bin/ranger", "fm")

#%USAGE: $ diff -u A B | diff-so-fancy
ab("/usr/bin/diff-so-fancy", "dfc")

ab("/@/airy/grep/ctl/repo", "re")
ab("/@/airy/grep/ctl/ia", "rs")

ab("/@/just/ctl", "j")
ab("/@/just/ctl", "just")

ab("/@/airy/hpx/scr/rot")
ab("/@/airy/init/bin/xcv")
ab("/@/airy/open/bin/man")
ab("/@/airy/open/bin/actualee")

ab("xc", at="/@/airy/xsel/bin")
ab("xci", at="/@/airy/xsel/bin")
ab("xcio", at="/@/airy/xsel/bin")
ab("xco", at="/@/airy/xsel/bin")
ab("xcx", at="/@/airy/xsel/bin")
