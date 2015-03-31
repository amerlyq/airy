#!/usr/bin/env bash

source ~/.bash_export
if [ $? -ne 0 ]; then echo "nnoo!"; exit; fi


if [ ! "$1" == "-w" ] && [ "$CURR_PLTF" == "Linux" ]
then
    sudo="sudo"
    VMs="$HOME/VMs"
else
    sudo=""
    VMs="${2:-/e/VMs}"
    PATH="$PATH:/c/Program Files/Oracle/VirtualBox"
    printf "\nYou need to run this script as Administrator!\n"
fi
VNM=Arch64
ost=ArchLinux_64
vimg="$VMs/${VNM}/${VNM}.vmdk"
vbox="${vimg%.*}.vbox"

# =======================================================================

printf "\n>>> ${VNM} guest image <<<\n"

if [ "$1" == "-r" ]; then rm -rf "${vimg%/*}"; fi
mkdir -p "${vimg%/*}"


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
        "home") VMOPTS="--memory 1024" ;;
        "work") VMOPTS="--memory 1024" ;;  # "--macaddress1 ${WORK_MAC?Need_WORK_MAC}" ;;
    esac
    case "$CURR_PLTF" in
        "Linux") VMOPTS="$VMOPTS --audio pulse  --audiocontroller hda  --accelerate2dvideo on"  ;;
        "MINGW") VMOPTS="$VMOPTS --audio dsound --audiocontroller ac97 --accelerate2dvideo off" ;;
    esac

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

    case "$CURR_PROF" in
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
