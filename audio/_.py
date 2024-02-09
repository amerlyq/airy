from airy.api import cp, ln, Pkg

# cp("blacklist-hdmi.conf", under="/etc/modprobe.d")

Pkg("pipewire")
# Pkg("lib32-pipewire")  # BAD: too many deps
Pkg("pipewire-alsa")
Pkg("pipewire-pulse")
# pacman -Ss pipewire-media-session
Pkg("wireplumber")
Pkg("qpwgraph")


# SRC: https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/2152
# DEBUG: $ chrt -a -p $(pidof pipewire)
# MAYBE: $ id | grep -qwF adbusers || sudo gpasswd -a "${LOGNAME:?}" adbusers
# cp("99-pipewire.conf", under="/etc/security/limits.d")
# OFF: https://gitlab.freedesktop.org/pipewire/pipewire/-/wikis/Performance-tuning#rlimits
# BET: rtkit
Pkg("rtkit")

# OFF: https://wiki.archlinux.org/title/WirePlumber
#   NICE: disable unnecessary HDMI outputs from menu
# FAIL: doesn't disable anything -- TRY:FIND: how to tweak SOF/modprobe itself
# cp("cfg/51-hdmi-disable.lua", under="~/.config/wireplumber/main.lua.d")
