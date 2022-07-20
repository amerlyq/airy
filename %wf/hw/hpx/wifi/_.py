from just.airy.api import Pkg

# ALSO: uncomment $ echo WIRELESS_REGDOM="UA" >> /etc/conf.d/wireless-regdom
Pkg("wireless-regdb")

# ALSO: for !tlp
# systemctl mask systemd-rfkill.socket
# systemctl mask systemd-rfkill.service
