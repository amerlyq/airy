from pathlib import Path
from airy.api import cp, ln, Aur

# Aur("kbdd-git")

cp("unit/10-xkb-hpx.conf", under="/etc/X11/xorg.conf.d")

for d in "compat rules symbols types".split():
    for s in Path("cfg").joinpath(d).iterdir():
        ln(s, under=f"/usr/share/X11/xkb/{d}")
