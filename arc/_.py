from airy.api import cp, Pkg

Pkg("avfs")

# systemctl --user enable --now avfs.service
cp("avfs.service", under="~/.config/systemd/user")
