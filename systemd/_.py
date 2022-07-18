from just.airy.api import ln, cp, Pkg

# FIXED※⡢⢳⡪⠒ stop spamming journal on each sudo
cp("cfg/system-auth" , under="/etc/pam.d")
