# vim: ft=sh
sudo pacman -Syu
sudo pacman -S binutils make gcc fakeroot 
sudo pacman -S expac yajl git

mkdir ipacaur && cd ipacaur
curl -o PKGBUILD 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=cower'
makepkg PKGBUILD  # --skippgpchecksudo
sudo pacman -U cower*.tar.xz
curl -o PKGBUILD 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=pacaur'
makepkg PKGBUILD
sudo pacman -U pacaur*.tar.xz
cd .. && rm -r ipacaur
