from airy.api import Pkg, cp, ln

Pkg("picom")

ln("picom.conf", under="~/.config/picom")

# systemctl --user enable --now picom.service
cp("picom.service", under="~/.config/systemd/user")
