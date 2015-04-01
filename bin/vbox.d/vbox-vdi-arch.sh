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
vimg="$VMs/${VNM}/${VNM}.vdi"
vbox="${vimg%.*}.vbox"
install_iso="$VMs/img/archlinux-2015.03.01-dual.iso"

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

