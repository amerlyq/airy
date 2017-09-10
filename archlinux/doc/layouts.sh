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
## WARN: some systems can only use gpt+uefi
##    => USE single-partition crypto-mbr+bios
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

# sdb               8:16   0 931.5G  0 disk
# ├─sdb1            8:17   0 931.5G  0 part
# │ └─luks        254:6    0 931.5G  0 crypt
# │   ├─ws-swap   254:7    0     4G  0 lvm
# │   ├─ws-root   254:8    0    40G  0 lvm
# │   ├─ws-pkgs   254:9    0    20G  0 lvm
# │   ├─ws-user   254:10   0    40G  0 lvm
# │   ├─ws-data   254:11   0   200G  0 lvm
# │   └─ws-work   254:12   0 627.5G  0 lvm
# └─sdb2            8:18   0   992K  0 part


## NOTE: format LV partitions
mkswap -L swap -f /dev/mapper/ws-swap
mkfs.btrfs -L root -f /dev/mapper/ws-root
mkfs.ext4 -L pkgs /dev/mapper/ws-pkgs
mkfs.btrfs -L user -f /dev/mapper/ws-user
mkfs.ext4 -L data /dev/mapper/ws-data
mkfs.btrfs -L work -f /dev/mapper/ws-work


## NOTE: create root btrfs layout
mount -o noatime,compress=lzo,autodefrag /dev/mapper/ws-root /mnt
btrfs quota enable /mnt
btrfs subvolume create /mnt/@
mkdir -vp /mnt/@/{.snapshots,boot,var,data,work,home/${myuser:?}}
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@/boot/grub
btrfs subvolume create /mnt/@/var/cache
btrfs subvolume create /mnt/@/var/log
# nodatacow per subvolume
chattr +C /mnt/@/var/log
mkdir -vp /mnt/@/var/cache/pacman/pkg
btrfs subvolume list /mnt
umount /mnt
# ├─@            /mnt
#   ├─/boot/grub
#   ├─/var/cache
#   └─/var/log
# └─@snapshots   /mnt/.snapshots


## NOTE: create user btrfs layout
mount -o noatime,compress=lzo,autodefrag /dev/mapper/ws-user /mnt
btrfs quota enable /mnt
btrfs subvolume create /mnt/@
mkdir -vp /mnt/@/{.snapshots,.cabal,.cache}
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@/.cabal/lib
btrfs subvolume create /mnt/@/.cache/pacaur
btrfs subvolume create /mnt/@/sdk
btrfs subvolume list /mnt
umount /mnt
# ├─@            /mnt/home/user
#   ├─ ~/.cabal/lib
#   ├─ ~/.cache/pacaur
#   └─ ~/sdk
# └─@snapshots   /mnt/home/user/.snapshots


## NOTE: create work btrfs layout
mount -o noatime,compress=lzo,autodefrag /dev/mapper/ws-work /mnt
btrfs subvolume create /mnt/@
umount /mnt


## NOTE: assemble mounted filesystem
mount -o noatime,compress=lzo,autodefrag,subvol=@ /dev/mapper/ws-root /mnt
mount -o noatime,compress=lzo,autodefrag,subvol=@snapshots /dev/mapper/ws-root /mnt/.snapshots
mount /dev/mapper/ws-pkgs /mnt/var/cache/pacman/pkg
myuser=...
mount -o noatime,compress=lzo,autodefrag,subvol=@ /dev/mapper/ws-user /mnt/home/${myuser:?}
mount -o noatime,compress=lzo,autodefrag,subvol=@snapshots /dev/mapper/ws-user /mnt/home/${myuser:?}/.snapshots
swapon /dev/mapper/ws-swap
mount /dev/mapper/ws-data /mnt/data
mount -o noatime,compress=lzo,autodefrag,subvol=@ /dev/mapper/ws-work /mnt/work


chown -R root:users /data /work
chmod -R 770 /data /work
# NEED:(music): for mpd install
mkdir -vp /data/{_dld,music,vm}

## FIXME: possible only after creating user
chown -R ${myuser:?}:${myuser:?} /home/${myuser:?}{,sdk,.cabal,.cache}
chmod -R 700 /home/${myuser:?}{,sdk,.cabal,.cache}


## NOTE: bake fstab
timedatectl set-timezone Europe/Kiev
timedatectl set-ntp true
pacstrap /mnt  base base-devel lvm2 btrfs-progs grub snapper
## FIX: manually remove swap of host system
genfstab -pU /mnt >> /mnt/etc/fstab

# pacstrap /mnt ntp sudo polkit wget git zsh vis
