from airy.api import Pkg, cp, ln

ln("unit/backlight.rules", under="/etc/udev/rules.d")
# USE: $ sudo udevadm control --reload-rules

# DONE: grep -q video /etc/group || sudo groupadd -r video
# TODO: groups | grep -qwF video || sudo gpasswd -a "${LOGNAME:?}" video
# TODO: relogin/reboot/chgrp
