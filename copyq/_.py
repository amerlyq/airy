from just.airy.api import Pkg, cp, ln

Pkg("copyq")

cp("copyq.conf", under="~/.config/copyq")
cp("copyq-commands.ini", under="~/.config/copyq")

cp("copyq.service" , under="~/.config/systemd/user")
# systemctl --user enable --now copyq.service
