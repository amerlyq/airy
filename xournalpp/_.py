from just.airy.api import Pkg, cp, ln

Pkg("xournalpp")

ln("cfg", file="~/.config/xournalpp")

# FAIL: Solution for: Gtk-WARNING **: Error loading theme icon - petermolnar.net ⌇⡢⣸⣒⡄
#   https://petermolnar.net/article/solution-for-gtk-warning-error-loading-theme-icon/
# for i in /usr/share/icons/*; do sudo gtk-update-icon-cache $i; done
# Icons - ArchWiki ⌇⡢⣸⣓⡖
#   https://wiki.archlinux.org/title/icons


# ALSO:
#   https://wiki.archlinux.org/title/List_of_applications/Utilities#On-screen_keyboards
#   https://wiki.archlinux.org/title/Touchegg
#   https://github.com/berkeleybross/easy-gesture
## DISABLED:FAIL(empty): $ xsetwacom list devices
# Pkg("xf86-input-wacom")
## DEBUG
# wacdump -f tpc /dev/ttyS0
# xidump -l
# xidump -u stylus
