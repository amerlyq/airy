#!/usr/bin/env bash

# Man
# http://www.virtualbox.org/manual/ch09.html
# http://scarygliders.net/2011/10/28/virtualbox-on-windows-7-host-with-raw-disk-access-solution-to-randomly-changing-disc-assignment-numbers/

source ~/.bash_export
if [ $? -ne 0 ]; then echo "nnoo!"; exit; fi


if [ "$CURR_PLTF" == "MINGW" ]
then WIN(){ return 0; } # true
else WIN(){ return 1; } # false
fi


# Home Profile
if [ "$CURR_PROF" != "home" ]; then echo "Error -- only home!"; exit 1; fi

if ! WIN; then
    VNM=Win7hdd
    ost=Windows7_64
    # Home
    disk=/dev/sda
    prts="1,2"
else
    VNM=Mint17hdd
    ost=Ubuntu_64
    cd 'c:\Program Files\Oracle\VirtualBox\'
    disk='\\.\PhysicalDrive0'
    prts="4,5"
fi


echo "${VNM} image"
vimg=~/VMs/${VNM}/${VNM}.vmdk
mbr=${vimg%.*}.mbr
mkdir -p "${mbr%/*}"
# read -p "Enter partitions numbers (like <4,5>):" prts
# ${prts?Error, enter parts}


# Find appropriate disk
#   L: sudo fdisk -l $disk
#   W: diskpart; list disk; select disk 0; list partition
sudo VBoxManage internalcommands listpartitions -rawdisk "$disk"


if ! WIN; then
    # echo "look at 'root group' rights on disk"
    group=$(ls -g "$disk" | awk '{print $3}')
    printf "Add user '${CURR_USER?Need CURR_USER}' to disk (or appropriate)
        group '${group?Need group}' (to be able to use key '-relative')\n"
    sudo usermod -a -G "$group" "$CURR_USER"
    echo "FIST: Re-login in this shell/session or reboot to update changes"
    echo "THEN: Check you are in 'disk' group"
    id
fi


# Create MBR to use with Win. Otherwise you get "grub> Unknown format"
if ! WIN; then
    if ! which nginx >/dev/null; then
        sudo apt-get install -y mbr
    fi
    echo "Installing MBR. Be carefull! Don't modify disk settings!"

    # The -e12 argument means I want the first and second partition enabled in
    # the MBR. This is critical to getting it all to work – otherwise the VM
    # won’t know which partition to enable.
    install-mbr --verbose -e12 --force "$mbr"
    ls -l "$mbr"
    # -rw-r--r-- 1 user user 512 2011-04-29 11:29 Win7.mbr
fi


# Create virtual proxy to raw disk 'sda' partition '1',
#   with specified mbr. Key '-relative' only for linux -- to put full access only on that partitions.

if ! VBoxManage list vms | grep -q "\<${VNM}\>"; then
    VBoxManage createvm --name "${VNM}" --ostype "$ost" --register

    # Сеть придётся основательно подрихтовать, так чтобы наружу торчал
    # правильный айпишник и мак из-под нутри виртуалки.
    VBoxManage modifyvm "${VNM}" --memory 3072 --vram 256 --pae on     \
        --accelerate3d on --accelerate2dvideo on                       \
        --ioapic on --cpus 2 --rtcuseutc on --cpuexecutioncap 100      \
        --hwvirtex on --nestedpaging on  --largepages on  --vtxvpid on \
        --boot1 dvd --boot2 disk --firmware bios                       \
        --clipboard bidirectional --monitorcount 1 --vrde off          \
        --audio pulse --audiocontroller ac97 --usb on --usbehci off    \
        --nic1 nat --nic2 intnet  --intnet2 "InnerVMs" --nic3 none --nic4 none
fi

if ! [ -f "$vimg" ]; then
    VBoxManage internalcommands createrawvmdk -filename "$vimg" \
        -rawdisk "$disk" -partitions $prts -mbr "$mbr" -relative
    #>> RAW host disk access VMDK file /home/vishalj/.VirtualBox/WinXP.vmdk created successfully.

    # TODO: Add grub2.iso to storages as primary and check mark 'SSD' on ide storage as secondary
    VBoxManage storagectl "${VNM}" --name "IDE Controller" --add ide --controller PIIX4
    VBoxManage storageattach "${VNM}" --storagectl "IDE Controller" \
        --port 0 --device 0 --type hdd --medium "$vimg"
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

# GUI: $ VirtualBox

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


