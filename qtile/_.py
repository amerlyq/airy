from airy.api import Pkg

Pkg("qtile")
Pkg("python-dbus-fast", why="qtile.send_notification")

ln("config.py", under="~/.config/qtile")
