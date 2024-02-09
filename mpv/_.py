from airy.api import ln, Pkg

Pkg("mpv")

ln("mpv.conf", under="~/.config/mpv")
ln("input.conf", under="~/.config/mpv")
ln("scripts", under="~/.config/mpv")


