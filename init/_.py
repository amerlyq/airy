from just.airy.api import ln, cp

ln("bin/xcv", under="/usr/local/bin")
ln("cfg/hook-sleep", under="/usr/lib/systemd/system-sleep")
cp("unit/autologin.conf", under="/etc/systemd/system/getty@tty1.service.d")

cp("unit/xsession.target" , under="~/.config/systemd/user")
