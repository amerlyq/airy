pkgs = [
    # DEPs(base): filesystem  gcc-libs  glibc  bash  coreutils  file  findutils  gawk
    # grep  procps-ng  sed  tar  gettext  pciutils psmisc  shadow  util-linux  bzip2
    # gzip  xz  licenses  pacman  systemd  systemd-sysvcompat  iputils  iproute2
    "base",
    # DEPs(base-devel): autoconf  automake  binutils  bison  fakeroot  file  findutils
    # flex  gawk  gcc  gettext  grep  groff  gzip  libtool  m4  make  pacman  patch
    # pkgconf  sed  sudo  systemd  texinfo  util-linux  which
    "base-devel",
    "linux linux-headers reflector ntp lvm2 grub sudo polkit".split(),
    "man-db man-pages time".split(),
]
