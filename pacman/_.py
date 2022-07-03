from just.airy.api import Pkg

# [⡢⣁⢫⣪] ⊞ 30m HACK: pikaur makepkg shallow clones ※⡢⣁⢬⡏
# $ v /usr/share/makepkg/source/git.sh
# [[ -n $fragment ]] && shallow= || shallow='--single-branch --depth=1'
# if ! git clone --mirror $shallow "$url" "$dir"; then
print("FIXME: auto-patch")

Pkg("pacman")
Pkg("pacman-contrib")
Pkg("pkgfile")  # grep packages content w/o downloading

## TODO:
# cp("", file="/etc/makepkg.conf")
