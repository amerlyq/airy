from just.airy.api import cp, Pkg

# cp("blacklist-hdmi.conf", under="/etc/modprobe.d")

Pkg("pipewire")
# Pkg("lib32-pipewire")  # BAD: too many deps
Pkg("pipewire-alsa")
Pkg("pipewire-pulse")
Pkg("wireplumber")
Pkg("qpwgraph")
