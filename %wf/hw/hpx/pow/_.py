from airy.api import Pkg, ln

# ln("hpx.conf", under="/etc/tlp.d")

# ONELINE: $ /d/airy/airy/bin/linkcp -ct '/etc/systemd/logind.conf.d' -- suspend-inof-poweroff.conf
ln("suspend-inof-poweroff.conf", under="/etc/systemd/logind.conf.d")

## FAIL: does not work
# Pkg("thermald")
Pkg("tlp")
Pkg("tlpui")
