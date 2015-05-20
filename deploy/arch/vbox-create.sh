#!/usr/bin/env bash
source ~/.bash_export || exit $?
source ~/.bash/functions.d/vbox || exit $?
ARGS="$@"

VNM=Arch64
ost=ArchLinux_64
if [ ! "$ARGS" == "-w" ] && [ "$CURR_PLTF" == "Linux" ]
then
    sudo="sudo"
    VMs="$HOME/VMs"
    SERIAL="/tmp/vbox-${VNM}S0"
else
    sudo=""
    VMs="${2:-/e/VMs}"
    PATH="$PATH:/c/Program Files/Oracle/VirtualBox"
    printf "\nYou need to run this script as Administrator!\n"
    SERIAL='\\.\pipe\'"vbox-${VNM}S0"
fi
vimg="$VMs/${VNM}/${VNM}.vdi"
vbox="${vimg%.*}.vbox"
install_iso="$(find "$VMs" -type f -name "archlinux*iso")"
VBOX_PORT=2822
GUEST_NET=vboxnet0

# =======================================================================

printf "\n>>> ${VNM} guest image <<<\n"

if [ "$ARGS" == "-r" ]; then rm -rf "${vimg%/*}"; fi
mkdir -p "${vimg%/*}"


if is_vm_exist "$VNM"; then case "$ARGS" in
-d|-r) VBoxManage unregistervm "${VNM}" ;; #--delete
-m) printf "VM exist, updating settings!\n" ;;
 *) squit "\n!!! ERR: There are already such VM: ${VNM} !!!\n";
esac; else case "$ARGS" in
-m) squit "There no such VM as '${VNM}'"
esac; fi

if is_vm_run "$VNM"; then
    if ask_confirm "Shutdown to modify?"
    then VBoxManage controlvm "${VNM}" poweroff
    else squit; fi
fi

if [ ! -f "$vbox" ]; then
    VBoxManage createvm --name "${VNM}" --ostype "$ost" --basefolder "$VMs" --register

    case "$CURR_PROF" in  # 100MB recovery, Win7, Data
        "home") VMOPTS="--memory 1024" ;;
        "work") VMOPTS="--memory 1024" ;;  # "--macaddress1 ${WORK_MAC?Need_WORK_MAC}" ;;
    esac
    # For Windows Guests only:  --accelerate2dvideo on
    case "$CURR_PLTF" in
        "Linux") VMOPTS="$VMOPTS --audio pulse  --audiocontroller hda  --accelerate2dvideo off"  ;;
        "MINGW") VMOPTS="$VMOPTS --audio dsound --audiocontroller ac97 --accelerate2dvideo off" ;;
    esac

    # Add host-only network in Host vbox and check it:
    if ! VBoxManage list -l hostonlyifs | grep -q "$GUEST_NET"; then
        VBoxManage hostonlyif create
        VBoxManage dhcpserver add --ifname "$GUEST_NET" --enable
        ifconfig "$GUEST_NET"
    fi

    # (virtualization options Only for Intel Host)
    VBoxManage modifyvm "${VNM}" ${VMOPTS} --vram 128 --pae on         \
        --ioapic on --cpus 2 --rtcuseutc on --cpuexecutioncap 100      \
        --hwvirtex on --nestedpaging on  --largepages on  --vtxvpid on \
        --boot1 dvd --boot2 disk --firmware bios  --accelerate3d on    \
        --clipboard bidirectional --monitorcount 1 --vrde off          \
        --usb on --usbehci off --nic1 nat --nic2 hostonly --hostonlyadapter2 "${GUEST_NET}"
    # Host-only: https://forums.virtualbox.org/viewtopic.php?f=8&t=34396
    # Intranet: --nic3 intnet  --intnet3 "InnerVMs"
    add_port_forward "${VNM}" "${VNM}_ssh" "tcp,,$VBOX_PORT,,22"

    # Provide virtual serial port to debug guest kernel
    #   Install Arch from serial port:  https://wiki.archlinux.org/index.php/Working_with_the_serial_console
    VBoxManage modifyvm "${VNM}" --uart1 0x3F8 4 --uartmode1 server "$SERIAL"

    # Only if Extensions installed
    # --usbehci on
    # --defaultfrontend default|<name>

    ## Headless
    # VBoxManage modifyvm "${VNM}" --memory 1024 --vram 16 --pae on      \
    #     --ioapic on --cpus 2 --rtcuseutc on --cpuexecutioncap 100      \
    #     --hwvirtex on --nestedpaging on  --largepages on  --vtxvpid on \
    #     --boot1 dvd --boot2 disk --firmware bios  --accelerate3d off   \
    #     --clipboard disabled --monitorcount 1 --vrde off --audio none  \
    #     --usb off --usbehci off --nic1 nat --nic2 hostonly

    sed -i '/ShowMiniToolBar/ s/\(value="\)\w\+"/\1no"/' "$vbox"
fi



if [ ! -f "$vimg" ]; then
    case "$CURR_PROF" in
        "home") HDDOPTS="--nonrotational on"
            printf "\n!!! IF NOT SSD: remove --nonrotational option !!!\n\n"
            ;;
        "work"|*) HDDOPTS="" ;;
    esac

    VBoxManage storagectl "${VNM}" --name "IDE"  --add ide \
        --controller PIIX4 --hostiocache on --bootable on
    VBoxManage storageattach "${VNM}" --storagectl "IDE" \
        --port 0 --device 0 --type dvddrive --medium "$install_iso"

    VBoxManage createhd --filename "$vimg" \
        --size 20480 --format VDI --variant Standard
    VBoxManage storagectl "${VNM}" --name "SATA" --add sata \
        --controller IntelAHCI --hostiocache on --portcount 1
    VBoxManage storageattach "${VNM}" --storagectl "SATA" \
        --port 0 --device 0 --type hdd $HDDOPTS --medium "$vimg"
fi

echo "W: vbox '${VNM}' vm"
