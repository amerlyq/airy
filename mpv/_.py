from airy.api import Pkg, ln

Pkg("mpv")
# NICE: preview when hovering over timeline
#   WTF: doesn't work?
Aur("mpv-thumbfast-git")

ln("mpv.conf", under="~/.config/mpv")
ln("input.conf", under="~/.config/mpv")
ln("scripts", under="~/.config/mpv")
