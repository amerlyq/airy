#!/usr/bin/env bash

# GUI: $ VirtualBox

# Man
# http://www.virtualbox.org/manual/ch09.html
# http://scarygliders.net/2011/10/28/virtualbox-on-windows-7-host-with-raw-disk-access-solution-to-randomly-changing-disc-assignment-numbers/

source ~/.bash_export
if [ $? -ne 0 ]; then echo "nnoo!"; exit; fi


if [ "$CURR_PLTF" == "MINGW" ]
then WIN(){ return 0; } # true
else WIN(){ return 1; } # false
fi

if WIN; then exit; fi
VMs="$HOME/VMs"

# Home Profile
if [ "$CURR_PROF" != "home" ]; then echo "Error -- only home!"; exit 1; fi


if ! WIN; then
    VNM=Win7hdd
    ost=Windows7_64
    # Home
    disk=/dev/sda
    prts="1,2,3"    # 100MB recovery, Win7, Data
else
    VNM=Mint17hdd
    ost=Ubuntu_64
    cd 'c:\Program Files\Oracle\VirtualBox\'
    disk='\\.\PhysicalDrive0'
    prts="4,5"
fi


printf "\n>>> ${VNM} guest image <<<\n"

vimg="$VMs/${VNM}/${VNM}.vmdk"
mbr="${vimg%.*}.mbr"
grub="${vimg%/*}/grub2.iso"


if [ "$1" == "-r" ]; then rm -rf "${vimg%/*}"; fi
mkdir -p "${vimg%/*}"


if [ -z "$prts" ]; then
# Find appropriate disk
#   L: sudo fdisk -l $disk
#   W: diskpart; list disk; select disk 0; list partition
    sudo VBoxManage internalcommands listpartitions -rawdisk "$disk"
    read -p "Enter wished partitions numbers (like <4,5>):" prts
    ${prts?Error, not entered partitions}
fi

printf "\n!!! Check if you are in 'disk' group\n"
if ! id | grep '(disk)'; then
    # Look at current disk rights 'root group'
    group=$(ls -g "$disk" | awk '{print $3}')
    printf "Add user '${CURR_USER?Need CURR_USER}' to disk (or appropriate)
        group '${group?Need group}' (to be able to use key '-relative')\n"
    sudo usermod -a -G "$group" "$CURR_USER"

    printf "\n!!! Re-login in this shell/session or reboot to update changes in Groups\n"
    exit
fi


# Create MBR to use with Win guest. Otherwise you get "grub> Unknown format"
if [ ! -f "$mbr" ]; then
    if ! which install-mbr >/dev/null; then
        sudo apt-get install -y mbr
    fi
    printf "\n!!! Installing MBR. Be carefull! Don't modify disk settings !!!\n\n"

    # -e12 -- try to boot from partitions 1,2 (enable them)
    install-mbr --verbose -e12 --force "$mbr"
    ls -l "$mbr"
    # -rw-r--r-- 1 user user 512 2011-04-29 11:29 Win7.mbr
fi


# Create virtual proxy to raw disk 'sda' partition '1',
#   with specified mbr. Key '-relative' only for linux -- to put full access only on that partitions.
if VBoxManage list vms | grep -q "\<${VNM}\>"; then
    if [ "$1" == "-d" ] || [ "$1" == "-r" ]; then
        VBoxManage unregistervm "${VNM}" #--delete
    else
        printf "\n!!! ERR: There are already such VM: ${VNM} !!!\n\n"
        exit
    fi
fi


if [ ! -f "${vimg%.*}.vbox" ]; then
    VBoxManage createvm --name "${VNM}" --ostype "$ost" --basefolder "$VMs" --register

    # Сеть придётся основательно подрихтовать, так чтобы наружу торчал
    # правильный айпишник и мак из-под нутри виртуалки.
    VBoxManage modifyvm "${VNM}" --memory 3072 --vram 256 --pae on     \
        --accelerate3d on --accelerate2dvideo on                       \
        --ioapic on --cpus 2 --rtcuseutc on --cpuexecutioncap 100      \
        --hwvirtex on --nestedpaging on  --largepages on  --vtxvpid on \
        --boot1 dvd --boot2 disk --firmware bios                       \
        --clipboard bidirectional --monitorcount 1 --vrde off          \
        --audio pulse --audiocontroller hda --usb on --usbehci off    \
        --nic1 nat --nic2 intnet  --intnet2 "InnerVMs" --nic3 none --nic4 none
fi


if [ ! -f "$grub" ]; then
    if ! which xorriso  >/dev/null; then
        sudo apt-get install -y xorriso
    fi

    exclude="{10_linux_proxy,33_memtest86+,34_linux_proxy}"
    eval "sudo chmod -x /etc/grub.d/$exclude"
    mkdir -p /tmp/iso/boot/grub
    cd /tmp/iso/boot/grub
    sudo grub-mkconfig > grub.cfg
    eval "sudo chmod +x /etc/grub.d/$exclude"

    grub-mkrescue --modules="linux ext2 fat fshelp ls boot ntfs" --output="$grub" /tmp/iso #pc
fi


if [ ! -f "$vimg" ]; then
    printf "\n!!! If not SSD: remove --nonrotational option !!!\n\n"

    VBoxManage internalcommands createrawvmdk -filename "$vimg" \
        -rawdisk "$disk" -partitions $prts -mbr "$mbr" -relative
    #>> RAW host disk access VMDK file /home/vishalj/.VirtualBox/WinXP.vmdk created successfully.

    VBoxManage storagectl "${VNM}" --name "IDE"  --add ide \
        --controller PIIX4 --hostiocache on --bootable on
    VBoxManage storageattach "${VNM}" --storagectl "IDE" \
        --port 0 --device 0 --type dvddrive --medium "$grub"

    VBoxManage storagectl "${VNM}" --name "SATA" --add sata \
        --controller IntelAHCI --hostiocache on --portcount 1
    VBoxManage storageattach "${VNM}" --storagectl "SATA" \
        --port 0 --device 0 --type hdd --nonrotational on --medium "$vimg"
fi


# TODO: if I can't to make grub2 or bcdedit loader
# Set the VM to mount the DVD drive and put in your Vista DVD. Start the VM.
# Press F12 and select the DVD drive to start (c). Let Win7 setup start, pick a
# language, and then click the ‘Repair installation’ option. Go through
# automatic repair, and then let the VM restart. This time it should go into
# Win7 running off the raw disk.

# In my case this was caused by wrong bios SATA mode setting. I installed
# windows 7 with bios SATA mode set to RAID so windows installed only RAID
# drivers. Since VM is using AHCI mode to access harddisks, windows doesn’t
# have proper driver installed for it. Microsoft has made a fix for this
# http://support.microsoft.com/kb/922976, you must run this fix before changing
# SATA mode to AHCI or running VM in AHCI. Still I recommend changing the bios
# setting to AHCÍ before even installing windows.


# Note: For me the SATA emulation for the RAW disk (under VirtualBox) did not
# work. I had to use the IDE emulation for the real SATA disk to get this
# working. There is some patch available to break windows binding to a given
# SATA driver and go more generic, but I did not try that yet.

# I tried to virtualize my old physical Windows XP hard disk partition and when
# booting nothing happened after starting mode menu choice. No error, but no
# Windows too :) (even 'safe mode' do not work)
# I found the solution from:
# http://doc.ubuntu-fr.org/utilisateurs/brazz/virtualbox#utilisation_d_un_disque_dur_physique_dans_virtual_box
# So, author advises that IO APIC must be activated from VM settings but I do
# not understand the exact role of this feature.


# --discard on option (after --nonrotational on) specifies that vdi image will be
# shrunk in response to trim command from guest OS. Following requirements must
# be met:
#     disk format must be VDI
#     cleared area must be at least 1MB (size)
#     [probably] cleared area must be cover one or more 1MB blocks (alignment)
#
# Obviously guest OS must be configured to issue trim command, typically that
# means guest OS is made to think the disk is an SSD. Ext4 supports -o discard
# mount flag; OSX probably requires additional settings as by default only
# Apple-supplied SSD's are issued this command. Windows ought to automatically
# detect and support SSD's at least in versions 7 and 8, I am not clear if
# detection happens at install or run time. Linux exFAT driver (courtesy of
# Samsung) supports discard command. It is not clear if Microsoft
# implementation of exFAT supports same, even though the file system was
# designed for flash to begin with.
#
# Alternatively there are ad hoc methods to issue trim, e.g. Linux fstrim
# command, part of util-linux package.
