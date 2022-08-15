from just.airy.api import Pkg, cp, ln

Pkg("copyq")

ln("copyq.conf", under="~/.config/copyq")
ln("copyq-commands.ini", under="~/.config/copyq")

cp("copyq.service" , under="~/.config/systemd/user")
# systemctl --user enable --now copyq.service
