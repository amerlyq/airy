from airy.api import cp

cp("blacklist-bt.conf", under="/etc/modprobe.d")

# ALSO: for !tlp
# systemctl mask systemd-rfkill.socket
# systemctl mask systemd-rfkill.service
