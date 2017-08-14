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

# Default AES cipher in XTS mode (effective key 256-bit)
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

## INFO: check LV aligning inside lvm (to adjust lvm if needed)
# https://www.percona.com/blog/2011/06/09/aligning-io-on-a-hard-disk-raid-the-theory/
# https://www.anchor.com.au/blog/2012/10/the-difference-between-booting-mbr-and-gpt-with-grub/
# +++ http://rainbow.chard.org/2013/01/30/how-to-align-partitions-for-best-performance-using-parted/
# CASE:(check if sda5/"Start" is aligned to 1MB):
#   0 == 4198400 % 2048 (1MB stripe / 512 sector size)
parted /dev/sda unit s print   # ALT: fdisk -lu /dev/sda

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
lvcreate lvm -Wy --yes -L 4G -C y -n swap
lvcreate lvm -Wy --yes -L 40G -n root
lvcreate lvm -Wy --yes -L 40G -n home
lvcreate lvm -Wy --yes -l +100%FREE -n media
lvs
