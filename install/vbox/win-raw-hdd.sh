#!/bin/bash -e
source ~/.shell/profile || exit

### MBR unnecessary if use whole disk, but you need grub. And vice versa.
### But for partitioned disk Windows and Office will lost activations.
# SEE:
#   http://gparted.org/h2-fix-msdos-pt.php
# Migration from RAW
#   http://superuser.com/questions/237782/virtualbox-booting-cloned-disk/253417#253417


# GUI: $ VirtualBox

# Man
# http://www.virtualbox.org/manual/ch09.html
# http://scarygliders.net/2011/10/28/virtualbox-on-windows-7-host-with-raw-disk-access-solution-to-randomly-changing-disc-assignment-numbers/

# Need to add installing proprietary VBox by adding ppa.
# http://blog.amhill.net/2010/01/27/linux-ftw-using-virtualbox-with-an-existing-windows-partition/comment-page-1/

# Repair -- some options
# 1. Rarely load into raw windows -- repair once, and each time when needed
# 2. Fix generated mbr by hex: http://en.wikipedia.org/wiki/Master_boot_record
#   Problem -- broken rules for mbr: http://gparted.org/h2-fix-msdos-pt.php
# 3. Use full disk, but mbr with only one entry to windows. Not secure.
# 4. Two bcdedit options -- original and repaired for vbox.


# Available Profiles
if [ "$CURR_PROF" != "home" -a "$CURR_PROF" != "work" ]; then
    echo "Error -- settings only for 'home' and 'work'!"
    exit 1
fi



if [ ! "$1" == "-w" ] && [ "$CURR_PLTF" == "Linux" ]
then
    sudo="sudo"
    VMs="$HOME/VMs"
    VNM=Win7hdd
    ost=Windows7_64
    disk=/dev/sda
    boot_ent="os-prober"
    case "$CURR_PROF" in
        "home") prts="1,2,3" ;;   # Recovery, Win7, Data
        "work") prts="1,2,8" ;;
    esac

    printf "\n!!! Check if you are in 'disk' group\n"
    if ! id | grep '(disk)'; then
        # Look at current disk rights 'root group'
        group=$(ls -g "$disk" | awk '{print $3}')
        printf "Adding user '${CURR_USER?Need CURR_USER}' to disk (or appropriate)
            group '${group?Need group}' (to be able to use key '-relative')\n"
        sudo usermod -a -G "$group" "$CURR_USER"

        printf "\n!!! Re-login in this shell/session or reboot to update changes in Groups\n"
        exit 0
    fi

else
    sudo=""
    VMs="${2:-/e/VMs}"
    VNM=Mint17hdd
    ost=Ubuntu_64
    disk="\\\\.\\GLOBALROOT\\ArcName\\multi(0)disk(0)rdisk(0)" #\\.\PhysicalDrive0
    boot_ent="linux"
    case "$CURR_PROF" in
        "home") prts="6,5" ;;
        "work") prts="3,5,6,7" ;; # boot,swap,root,home
    esac
    PATH="$PATH:/c/Program Files/Oracle/VirtualBox"
    printf "\nYou need to run this script as Administrator!\n"
fi



vimg="$VMs/${VNM}/${VNM}.vmdk"
vbox="${vimg%.*}.vbox"
 mbr="${vimg%.*}.mbr"
grub="${vimg%/*}/grub2.iso"
tmp_iso=/tmp/iso/boot/grub


# Find appropriate disk
#   L: sudo fdisk -l $disk
#   W: diskpart; list disk; select disk 0; list partition
if [ "$1" == "-l" ]; then
    $sudo VBoxManage internalcommands listpartitions -rawdisk "$disk"
    exit 0
fi


# =======================================================================

printf "\n>>> ${VNM} guest image <<<\n"

if [ -z "$prts" ]; then
    sudo VBoxManage internalcommands listpartitions -rawdisk "$disk"
    read -p "Enter wished partitions numbers (like <6,5>):" prts
    ${prts?Error, not entered partitions}
fi


if [ "$1" == "-r" ]; then rm -rf "${vimg%/*}"; fi
mkdir -p "${vimg%/*}"


# # Create MBR to use with Win guest. Otherwise you get "grub> Unknown format"
# if [ ! -f "$mbr" ] && [ "$CURR_PLTF" == "Linux" ]; then
#     if ! which install-mbr >/dev/null; then
#         sudo apt-get install -y mbr
#     fi
#     printf "\n!!! Creating MBR for ${prts}. Be carefull! Don't modify disk own settings !!!\n\n"
#     # Choose only from main 1-4 partitions, used in boot for neccessary OS
#     # bprts=${prts//,/}; bprts=${bprts:0:2}
#     bprts=${prts:0:1}
#
#     # -d 0x80 -- boot a first drive (starting from 128), not first disk
#     # -e12 -- try to boot from partitions 1,2 (enable them)
#     install-mbr --verbose --drive 0x80 -e${bprts} --force "$mbr"
#     # dd if=/dev/sda bs=512 count=1 of="$mbr"
#     # cp ~/tmp/win7mbr512x1 "$mbr"
#
#     ls -l "$mbr"
#     # -rw-r--r-- 1 user user 512 2011-04-29 11:29 Win7.mbr
#     printf "\nMBR generated successfully\n"
# fi

# This iso could be unneccessary if mbr contains only one entry to boot...
if [ ! -f "$grub" ] && [ "$CURR_PLTF" == "Linux" ]; then
    if ! which xorriso  >/dev/null; then
        sudo apt-get install -y xorriso
    fi

    mkdir -p "$tmp_iso"

    exclude=$(ls /etc/grub.d | sed '/^[0-9]\{2\}_/!d; /header\|'"$boot_ent"'$/d' | xargs)
    eval "sudo chmod -x /etc/grub.d/{${exclude// /,}}"
    sudo grub-mkconfig > "$tmp_iso/grub.cfg"
    eval "sudo chmod +x /etc/grub.d/{${exclude// /,}}"

# sed -i '/^### END \/etc\/grub.d\/40_custom ###$/i\
# set timeout_style=menu\
# if [ "${timeout}" = 0 ]; then\
#     set timeout=7\
# fi\
# printf 'set timeout=0
# menuentry "Windows7" --class windows {
#     #30_os-prober_proxy
#     insmod part_msdos
#     insmod ntfs
#     set root=(hd0,msdos1)
#     chainloader +1
# }' > ./grub.cfg

    # --modules="loadenv fshelp ls boot ntfs parttool chain search terminal"
    grub-mkrescue  --output="$grub" /tmp/iso #pc
fi

if [ "$1" == "-w" ]; then
    printf "\n Prerequisit files for raw linux guest was generated.\n"
    exit
fi

# =======================================================================

# Create virtual proxy to raw disk 'sda' partition '1',
#   with specified mbr. Key '-relative' only for linux -- to put full access only on that partitions.
if VBoxManage list vms | grep -q "\<${VNM}\>"; then
    if [ "$1" == "-d" ] || [ "$1" == "-r" ]; then
        VBoxManage unregistervm "${VNM}" #--delete
    else
        printf "\n!!! ERR: There are already such VM: ${VNM} !!!\n\n"
        exit 1
    fi
fi

if [ ! -f "$vbox" ]; then
    VBoxManage createvm --name "${VNM}" --ostype "$ost" --basefolder "$VMs" --register

    case "$CURR_PROF" in  # 100MB recovery, Win7, Data
        "home") VMOPTS="--memory 3072" ;;
        "work") VMOPTS="--memory 2560 --macaddress1 ${WORK_MAC?Need_WORK_MAC}" ;;
    esac
    case "$CURR_PLTF" in
        "Linux") VMOPTS="$VMOPTS --audio pulse  --audiocontroller hda  --accelerate2dvideo on"  ;;
        "MINGW") VMOPTS="$VMOPTS --audio dsound --audiocontroller ac97 --accelerate2dvideo off" ;;
    esac
    # Сеть придётся основательно подрихтовать, так чтобы наружу торчал
    # правильный айпишник и мак из-под нутри виртуалки.
    VBoxManage modifyvm "${VNM}" ${VMOPTS} --vram 128 --pae on         \
        --ioapic on --cpus 2 --rtcuseutc on --cpuexecutioncap 100      \
        --hwvirtex on --nestedpaging on  --largepages on  --vtxvpid on \
        --boot1 dvd --boot2 disk --firmware bios  --accelerate3d on    \
        --clipboard bidirectional --monitorcount 1 --vrde off          \
        --usb on --usbehci off --nic1 nat --nic2 none --nic3 none --nic4 none
    # Intranet: --nic2 intnet  --intnet2 "InnerVMs"

    sed -i '/ShowMiniToolBar/ s/\(value="\)\w\+"/\1no"/' "$vbox"
fi



if [ ! -f "$vimg" ]; then
    printf "\n!!! IF NOT SSD: remove --nonrotational option !!!\n\n"

    case "$CURR_PROF" in # 100MB recovery, Win7, Data
        "home") HDDOPTS="--nonrotational on" ;;
        "work") HDDOPTS="" ;;
    esac

    # if [ "$CURR_PLTF" == "Linux" ]; then IMGOPTS='-relative'; fi

    VBoxManage internalcommands createrawvmdk -filename "$vimg" -rawdisk "$disk"
    # VBoxManage internalcommands createrawvmdk -filename "$vimg" \
    #     -rawdisk "$disk" -partitions $prts -mbr "$mbr" $IMGOPTS
    #>> RAW host disk access VMDK file /home/vishalj/.VirtualBox/WinXP.vmdk created successfully.

    VBoxManage storagectl "${VNM}" --name "IDE"  --add ide \
        --controller PIIX4 --hostiocache on --bootable on
    VBoxManage storageattach "${VNM}" --storagectl "IDE" \
        --port 0 --device 0 --type dvddrive --medium "$grub"

    VBoxManage storagectl "${VNM}" --name "SATA" --add sata \
        --controller IntelAHCI --hostiocache on --portcount 1
    VBoxManage storageattach "${VNM}" --storagectl "SATA" \
        --port 0 --device 0 --type hdd $HDDOPTS --medium "$vimg"
fi


# TODO: if I can't to make grub2 or bcdedit loader
# Use automatic 'Repair installation' Win7_DVD option.

# In my case this was caused by wrong bios SATA mode setting. I installed
# windows 7 with bios SATA mode set to RAID so windows installed only RAID
# drivers. Since VM is using AHCI mode to access harddisks, windows doesn’t
# have proper driver installed for it. Microsoft has made a fix for this
# http://support.microsoft.com/kb/922976, you must run this fix before changing
# SATA mode to AHCI or running VM in AHCI. Still I recommend changing the bios
# setting to AHCÍ before even installing windows.


# Note: For me the SATA emulation for the RAW disk (under VirtualBox) did not
# work. I had to use the IDE emulation for the real SATA disk to get this
# working.


# Author advises that IO APIC must be activated from VM settings.
# http://doc.ubuntu-fr.org/utilisateurs/brazz/virtualbox#utilisation_d_un_disque_dur_physique_dans_virtual_box

# --discard on option (after --nonrotational on) specifies that vdi image will be
# shrunk in response to trim command from guest OS. Following requirements must
# be met:
#     disk format must be VDI
#     cleared area must be at least 1MB (size)
#     [probably] cleared area must be cover one or more 1MB blocks (alignment)

# Obviously guest OS must be configured to issue trim command, typically that
# means guest OS is made to think the disk is an SSD. Ext4 supports -o discard
# mount flag; OSX probably requires additional settings as by default only
# Apple-supplied SSD's are issued this command. Windows ought to automatically
# detect and support SSD's at least in versions 7 and 8, I am not clear if
# detection happens at install or run time. Linux exFAT driver (courtesy of
# Samsung) supports discard command. It is not clear if Microsoft
# implementation of exFAT supports same, even though the file system was
# designed for flash to begin with.

# Alternatively there are ad hoc methods to issue trim, e.g. Linux fstrim
# command, part of util-linux package.
