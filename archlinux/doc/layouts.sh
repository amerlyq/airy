# vim: ft=sh
# NOTE: mixed btrfs + snapshots layout

# ALSO:
# http://www.davideolianas.com/install-arch-linux-on-btrfs-subvolume-inside-luks-in-uefi.html
# https://gist.github.com/broedli/4f401e0097f185ba34eb#1-setup-ssh
# https://fogelholk.io/installing-arch-with-lvm-on-luks-and-btrfs/
# https://www.vultr.com/docs/install-arch-linux-with-btrfs-snapshotting
# ++ http://www.pavelkogan.com/2014/05/23/luks-full-disk-encryption/
# SEE: https://bbs.archlinux.org/viewtopic.php?id=144477
# https://wiki.archlinux.org/index.php/Dm-crypt/Encrypting_an_entire_system#Layout

## INFO: check existing partition table :: MBR/msdos OR GPT/gpt
parted /dev/sda print | grep ^Partition
# OR: gdisk -l /dev/sda


## NOTE: use GPT+GRUB for raw disk
# ALT:IA: fdisk/gdisk (MBR/GPT)
# OR:(non-interactive): parted -s -a opt /dev/sda ...
parted /dev/sda
# mklabel gpt
## NOTE: lvm-on-luks whole-disk partition
# mkpart primary 2048s 100%
# align-check opt 1
## NEED: for old BIOSes
## SEE: https://unix.stackexchange.com/questions/325886/bios-gpt-do-we-need-a-boot-flag
# set 1 boot on
## USE: (Ignore) -- min aligned on 4KiB block for GRUB
## HACK: keep main as sda1 -- create grub as last one
# mkpart primary 64s 2047s
# align-check min 2
# help set
# set 2 bios_grub on
# unit mib
# print
# quit


## INFO: check lvm partition alignment
##  -- to adjust "pvcreate --dataalignmentoffset" if needed
# https://www.percona.com/blog/2011/06/09/aligning-io-on-a-hard-disk-raid-the-theory/
# https://www.anchor.com.au/blog/2012/10/the-difference-between-booting-mbr-and-gpt-with-grub/
# +++ http://rainbow.chard.org/2013/01/30/how-to-align-partitions-for-best-performance-using-parted/
# CASE:(check if sda5/"Start" is aligned to 1MB):
#   0 == 4198400 % 2048 (1MB stripe / 512 sector size)
parted /dev/sda unit s print   # ALT: fdisk -lu /dev/sda


## NOTE: Default AES cipher in XTS mode (effective key 256-bit)
# SEE:DFL: $ cryptsetup --help
cryptsetup -s 512 luksFormat /dev/sda1
## INFO: check occupied key slots
cryptsetup luksDump /dev/sda1 | grep ABLED
# open encrypted container
cryptsetup luksOpen /dev/sda1 luks


## INFO: scanning / clean
lvmdiskscan
dmsetup ls --tree
# dmsetup remove /dev/mapper/luks  # NOTE: del old LVM completely
# vgremove -f ws  # NOTE: del only group, keeping LVM

## NOTE: init partition as Physical Volume
pvcreate --dataalignment 1m /dev/mapper/luks
pvcreate -f /dev/mapper/luks
pvdisplay
pvs

## NOTE: add PV to new Volume Group
vgcreate ws /dev/mapper/luks
vgdisplay
vgs


## NOTE: create LV partitions
lvcreate ws -Wy --yes -n swap -L 4G -C y
lvcreate ws -Wy --yes -n root -L 40G
lvcreate ws -Wy --yes -n pkgs -L 20G
lvcreate ws -Wy --yes -n user -L 40G
lvcreate ws -Wy --yes -n data -L 200G
lvcreate ws -Wy --yes -n work -l +100%FREE
lvs


## NOTE: format LV partitions
mkswap -L swap -f /dev/mapper/ws-swap
mkfs.btrfs -L root -f /dev/mapper/ws-root
mkfs.ext4 -L pkgs /dev/mapper/ws-pkgs
mkfs.btrfs -L user -f /dev/mapper/ws-user
mkfs.ext4 -L data /dev/mapper/ws-data
mkfs.btrfs -L work -f /dev/mapper/ws-work


## NOTE: create root btrfs layout
# BAD:CHECK: @var_log -- unmountable because of systemd -- NEED shutdown hook in mkinitcpio
mount -o noatime,compress=lzo,autodefrag /dev/mapper/ws-root /mnt
btrfs subvolume create /mnt/@{,snapshots,boot_grub,var_cache,var_log}
chattr +C /mnt/@var_log  # nodatacow per subvolume
mkdir -vp /mnt/@/{.snapshots,boot/grub,var/{cache,log},data,work}
mkdir -vp /mnt/@var_cache/pacman/pkg
mkdir -vp /mnt/@/home/${myuser:?}
umount /mnt
# ├─@            /mnt
# ├─@snapshots   /mnt/.snapshots
# ├─@boot_grub   /mnt/boot/grub
# ├─@var_cache   /mnt/var/cache
# └─@var_log     /mnt/var/log


## NOTE: create user btrfs layout
mount -o noatime,compress=lzo,autodefrag /dev/mapper/ws-user /mnt
btrfs subvolume create /mnt/@{,snapshots,cabal,pacaur,sdk}
mkdir -vp /mnt/@/{.snapshots,.cabal/lib,.cache/pacaur,sdk}
umount /mnt
# ├─@            /mnt/home/user
# ├─@snapshots   /mnt/home/user/.snapshots
# ├─@cabal       /mnt/home/user/.cabal/lib
# ├─@pacaur      /mnt/home/user/.cache/pacaur
# └─@sdk         /mnt/home/user/sdk


## NOTE: create work btrfs layout
mount -o noatime,compress=lzo,autodefrag /dev/mapper/ws-work /mnt
btrfs subvolume create /mnt/@
umount /mnt


## NOTE: assemble mounted filesystem
mount -o noatime,compress=lzo,autodefrag,subvol=@ /dev/mapper/ws-root /mnt
mount -o noatime,nodatacow,autodefrag,subvol=@var_log /dev/mapper/ws-root /mnt/var/log
mount -o noatime,compress=lzo,autodefrag,subvol=@snapshots /dev/mapper/ws-root /mnt/.snapshots
mount -o noatime,compress=lzo,autodefrag,subvol=@boot_grub /dev/mapper/ws-root /mnt/boot/grub
mount -o noatime,compress=lzo,autodefrag,subvol=@var_cache /dev/mapper/ws-root /mnt/var/cache
mount /dev/mapper/ws-pkgs /mnt/var/cache/pacman/pkg

myuser=...
mount -o noatime,compress=lzo,autodefrag,subvol=@ /dev/mapper/ws-user /mnt/home/${myuser:?}
mount -o noatime,compress=lzo,autodefrag,subvol=@snapshots /dev/mapper/ws-user /mnt/home/${myuser:?}/.snapshots
mount -o noatime,compress=lzo,autodefrag,subvol=@cabal /dev/mapper/ws-user /mnt/home/${myuser:?}/.cabal
mount -o noatime,compress=lzo,autodefrag,subvol=@pacaur /dev/mapper/ws-user /mnt/home/${myuser:?}/.cache/pacaur
mount -o noatime,compress=lzo,autodefrag,subvol=@sdk /dev/mapper/ws-user /mnt/home/${myuser:?}/sdk

swapon /dev/mapper/ws-swap
mount /dev/mapper/ws-data /mnt/data
mount -o noatime,compress=lzo,autodefrag,subvol=@ /dev/mapper/ws-work /mnt/work


## NOTE: bake fstab
timedatectl set-timezone Europe/Kiev
timedatectl set-ntp true
pacstrap /mnt  base base-devel lvm2 btrfs-progs grub
genfstab -pU /mnt >> /mnt/etc/fstab
