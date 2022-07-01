from just.airy.api import ln

ln("cfg/pam_environment", file="~/.pam_environment")


ln("/@/airy/qute/ctl/proxy", file="bw", under="/usr/local/bin")
ln("qutebrowser", at="/usr/bin", file="b", under="/usr/local/bin")
ln("nvim", at="/usr/bin", file="v", under="/usr/local/bin")
ln("nvim", at="/usr/bin", file="vim", under="/usr/local/bin")


ln("ranger", at="/usr/bin", file=",s", under="/usr/local/bin")
ln("/@/just/ctl", file="j", under="/usr/local/bin")
ln("/@/just/ctl", file="just", under="/usr/local/bin")

ln("/@/airy/hw/scr/rot", under="/usr/local/bin")
ln("/@/airy/init/bin/xcv", under="/usr/local/bin")

ln("xc", at="/@/airy/xsel/bin", under="/usr/local/bin")
ln("xci", at="/@/airy/xsel/bin", under="/usr/local/bin")
ln("xcio", at="/@/airy/xsel/bin", under="/usr/local/bin")
ln("xco", at="/@/airy/xsel/bin", under="/usr/local/bin")
ln("xcx", at="/@/airy/xsel/bin", under="/usr/local/bin")
