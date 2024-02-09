from airy.api import Pkg, ln

Pkg("zsh")
# Pkg("mcfly")
# Pkg("thefuck")
# Pkg("fzf")


def dln(nm: str) -> ln:
    return ln("cfg/" + nm, file="." + nm, under="~")


dln("zshrc")
dln("zlogin")

# sudo usermod -s /usr/bin/zsh $USER
