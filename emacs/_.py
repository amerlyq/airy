from just.airy.api import Pkg, ln

# PERF: ⌇⡢⣳⢱⣇
#   https://akrl.sdf.org/gccemacs.html
#   https://www.emacswiki.org/emacs/GccEmacs
Pkg("emacs-nativecomp")

ln("/@/plugins/spacemacs" , file="~/.emacs.d")
ln("spacemacs", at="cfg", file="~/.spacemacs")
ln("spacemacs.env", at="cfg", file="~/.spacemacs.env")
ln("swank.lisp", at="cfg", file="~/.swank.lisp")

## ALSO: session daemon
# svc_activate -uerR emacs
