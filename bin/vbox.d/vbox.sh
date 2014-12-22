source ~/.bash_export
source ~/.bash/functions
amScriptDir
# sudo apt-get install openssh-server
PATH="/c/Program Files/Oracle/VirtualBox:$PATH"
#echo $PATH

#VBoxManage setextradata x "VBoxInternal/Devices/pcnet/0/LUN#0/Config/ssh/Protocol"  TCP
#VBoxManage setextradata x "VBoxInternal/Devices/pcnet/0/LUN#0/Config/ssh/GuestPort" 22
#VBoxManage setextradata x "VBoxInternal/Devices/pcnet/0/LUN#0/Config/ssh/HostPort"  2222

# Creating new vm 7.1.3 Step by step:
# VBoxManage list ostypes
# VBoxManage createvm --name "Windows XP" --ostype WindowsXP --register
# VBoxManage modifyvm "${VNM}" ...
# VBoxManage createhd --filename "WinXP.vdi" --size 10000
# VBoxManage storagectl "Windows XP" --name "IDE Controller" --add ide --controller PIIX4
# VBoxManage storageattach "Windows XP" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium "WinXP.vdi"
# VBoxManage storageattach "Windows XP" --storagectl "IDE Controller" --port 0 --device 1 --type dvddrive --medium /full/path/to/iso.iso
# VBoxHeadless --startvm "Windows XP"

# 7.1.4 Remote USB
# Insert Flash-drive on one copm, use it on another!

add_port_forward() {
    if [ $# -eq 3 ]; then
        echo "Add $1 port forwarding rule '$2,$3'"
        # Delete if exist
        if VBoxManage showvminfo "${1}" | grep -q "Rule.*\<${2}\>" ; then
            VBoxManage modifyvm "${1}" --natpf1 delete "${2}"
            VBoxManage showvminfo "${1}" | grep "Rule.*\<${2}\>"
            echo "W: del"
        fi

        # Create if don't exist
        if ! VBoxManage showvminfo "${1}" | grep -q "Rule.*\<${2}\>" ; then
            VBoxManage modifyvm "${1}" --natpf1 "${2},${3}"
            VBoxManage showvminfo "${1}" | grep "Rule.*\<${2}\>"
            echo "W: crt"
        fi
        echo "W: vbox net configured"
    else echo "Number of $# args isn't enough"
    fi
}


VNM="Lubuntu"

if ! VBoxManage list vms | grep "\<${VNM}\>"; then
    echo "There no such VM as '${VNM}'"; squit;
fi

if VBoxManage list runningvms | grep -q "\<${VNM}\>"; then
    echo "Shutdown VM='${VNM}' before modifying its settings"; squit;
    # VBoxManage controlvm <vm> poweroff
fi

FL_GENERAL="\
    --ioapic on --cpus 2 --rtcuseutc on --cpuexecutioncap 100 --pae off \
    --hwvirtex on --nestedpaging on  --largepages on  --vtxvpid on \
    --boot1 dvd --boot2 disk --firmware bios"

echo "$CURR_PROF"
# After Creation (virtualization options Only for Intel Host)
# Slave-vboxes for build setups can have another settings
if [ "$CURR_PROF" == "work" ]; then # Main workstation
    VBoxManage modifyvm "${VNM}" --memory 2560 --vram 128 --accelerate3d on \
        ${FL_GENERAL} --clipboard bidirectional \
        --monitorcount 1 --vrde off --usb on --usbehci off \
        --nic1 nat --nic2 intnet  --intnet2 "InnerVMs" --nic3 none --nic4 none #--audio none
fi

if [ "$CURR_PROF" == "home" ]; then # Main headless server
    VBoxManage modifyvm "${VNM}" --memory 2048 --vram 64 --accelerate3d off \
        ${FL_GENERAL} --audio none --clipboard disabled \
        --monitorcount 1 --vrde off --usb on --usbehci off \
        --nic1 nat --nic2 intnet  --intnet2 "InnerVMs" --nic3 none --nic4 none
fi

add_port_forward "${VNM}" "Port_ssh" "tcp,,$SIR_PORT,,22"

echo "W: vbox '${VNM}' settings"
# Only if Extensions installed
# --usbehci on
# Wrong???
#--audio oss
#  used when starting this VM; see chapter 8.12, VBoxManage startvm,
#--defaultfrontend default|<name>
# VBoxManage startvm "VM name" --type headless
# Alt: but make background yourself!
# VBoxHeadless --startvm <uuid|name>  --vrde off


## 8.8.2 Networking settings :
# My build server model:
#   WWW--WinHost<--NAT-ServerGuest-Intranet-->{AndroidVM, CppBuild, enc}

# NAT for www

# Intranet to communicate securily between guests w/o sniffing in real eth adapter
# See 6.6 Internal networking, needs dhcp enabled to not set static ip's manually

# Access from Host into guest by ssh 6.7 Host-only networking
# (obsolete by port-forwarding, if you need only ssh access)
#VBoxManage modifyvm "${VNM}" --nic3 hostonly

# Keeping the NAT adapter and adding a second host-only adapter works amazing
# Also, I just added additional adapter and it worked, didn't need to edit the /etc/network/interfaces

# See options:
# VBoxManage modifyvm --help  2>&1 | grep 3d

amPause
