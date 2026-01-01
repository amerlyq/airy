from airy.api import Pkg, cp, ln

# sudo systemctl enable --now earlyoom.service
Pkg("earlyoom")

# FIXED※⡢⢳⡪⠒ stop spamming journal on each sudo
cp("cfg/system-auth", under="/etc/pam.d")

# FIXED※⡩⡌⠠⡺ dict can't connect to localhost when there is no active WiFi AP
cp("cfg/nsswitch.conf", under="/etc")
