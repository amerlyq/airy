from airy.api import Pkg, cp, ln

Pkg("my")

ln("cfg/my.conf", under="~/.config/my")

# systemctl --user enable --now my.service
cp("my.service", under="~/.config/systemd/user")
