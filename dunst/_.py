from airy.api import Aur, ln

# Pkg("dunst")
Aur("dunst-git")  # why="release is 6mo old"

# DEBUG $ busctl --user list | grep -F org.freedesktop.Notifications

## MAYBE: not needed, as it's dbus-activated ?
# systemctl --user enable --now dunst.service
# ALT:OLD: ./dunst.service

ln("dunstrc", under="~/.config/dunst")

ln("/usr/bin/dunstify", "notify-send", at="/b")
ln("/usr/bin/dunstify", "ntf", at="/b")
