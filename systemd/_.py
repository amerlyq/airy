from airy.api import ln, cp, Pkg

# sudo systemctl enable --now earlyoom.service
Pkg("earlyoom")

# FIXED※⡢⢳⡪⠒ stop spamming journal on each sudo
cp("cfg/system-auth" , under="/etc/pam.d")
