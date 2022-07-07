from just.airy.api import ln, cp, Pkg

Pkg("mpd")  # mpc

ln("/d/music" , under="~/.config/mpd")
ln("cfg/mpd.conf" , under="~/.config/mpd")

# CHECK: dir content -- BET link whole dir
# linkcp -t "$dir"/playlists ./radio/*

# FUT: patch keyval text file by .py w/o this script
# ./cfg/state.gen "$dir"/mpd.state

# FIXME: use UNIX socket
cp("unit/mpd.socket" , under="~/.config/systemd/user")
cp("unit/mpd.service" , under="~/.config/systemd/user")

# ALSO: mpd-log.service

## TODO: run manually FUT: sep action category for !airyctl
# systemctl --user enable mpd.service
# systemctl --user enable --now mpd.socket
