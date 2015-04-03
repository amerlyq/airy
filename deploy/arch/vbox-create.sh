#!/usr/bin/env bash
source ~/.bash_export || exit $?
source ~/.bash/functions.d/vbox || exit $?
ARGS="$@"

if [ ! "$ARGS" == "-w" ] && [ "$CURR_PLTF" == "Linux" ]
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
vimg="$VMs/${VNM}/${VNM}.vdi"
vbox="${vimg%.*}.vbox"
install_iso="$(find "$VMs" -type f -name "archlinux*iso")"
VBOX_PORT=2822

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
    case "$CURR_PLTF" in
        "Linux") VMOPTS="$VMOPTS --audio pulse  --audiocontroller hda  --accelerate2dvideo on"  ;;
        "MINGW") VMOPTS="$VMOPTS --audio dsound --audiocontroller ac97 --accelerate2dvideo off" ;;
    esac


    # (virtualization options Only for Intel Host)
    # Intranet: --nic2 intnet  --intnet2 "InnerVMs"
    #--nic3 none --nic4 none
    VBoxManage modifyvm "${VNM}" ${VMOPTS} --vram 128 --pae on         \
        --ioapic on --cpus 2 --rtcuseutc on --cpuexecutioncap 100      \
        --hwvirtex on --nestedpaging on  --largepages on  --vtxvpid on \
        --boot1 dvd --boot2 disk --firmware bios  --accelerate3d on    \
        --clipboard bidirectional --monitorcount 1 --vrde off          \
        --usb on --usbehci off --nic1 nat --nic2 none

    add_port_forward "${VNM}" "${VNM}_ssh" "tcp,,$VBOX_PORT,,22"

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
    printf "\n!!! IF NOT SSD: remove --nonrotational option !!!\n\n"

    case "$CURR_PROF" in
        "home") HDDOPTS="--nonrotational on" ;;
        "work") HDDOPTS="" ;;
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
