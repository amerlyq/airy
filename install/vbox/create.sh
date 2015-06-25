#!/usr/bin/env bash
source ~/.shell/profile || exit
source ./funcs || exit
source ./options || exit
cd $(dirname $(readlink -m ${0}))

# =======================================================================

### Default options (headless) ###
declare -A VMOPTS  # "${VMOPTS[@]/#/--}"
VMOPTS+=( [vram]=16  [accelerate3d]=off  [clipboard]=disabled
          [audio]=none  [usb]=off  [firmware]=bios  [pae]=on
          [ioapic]=on  [cpus]=2  [rtcuseutc]=on  [cpuexecutioncap]=100
          [hwvirtex]=on  [nestedpaging]=on  [largepages]=on  [vtxvpid]=on
          [boot1]=dvd  [boot2]=disk  [monitorcount]=1  [vrde]=off  [usbehci]=off
          [nic1]=nat  [nic2]=hostonly  [hostonlyadapter2]="${VBOX_NET?No}" )
# (virtualization options Only for Intel Host)
# Host-only: https://forums.virtualbox.org/viewtopic.php?f=8&t=34396
# Intranet: --nic3 intnet  --intnet3 "InnerVMs"

case "${CURR_PLTF?No}"
in Linux)
    VMOPTS+=( [audio]=pulse  [audiocontroller]=hda  [accelerate2dvideo]=off )
;; MINGW)
    VMOPTS+=( [audio]=dsound  [audiocontroller]=ac97  [accelerate2dvideo]=on )
;; *) echo "Unknown host platform" ;; esac

case "${CURR_PROF?No}"
in home)
    VMOPTS+=( [memory]=1024 )
;; work)  # 100MB recovery, Win7, Data
    VMOPTS+=( [memory]=1024 )  # "--macaddress1 ${WORK_MAC?Need_WORK_MAC}" ;;
;; esac

# =======================================================================

### Profiles ###
VBOX_PROF='arch-kernel'
source ./hosts || exit  # NOTE: loads profile inside
printf "\n>>> ${VNM?No VM name} guest image <<<\n"

# =======================================================================

### Arguments ###
ARGS="$@"

if [ "$ARGS" == "-c" ]; then rm -rf "${vimg%/*}"; fi
mkdir -p "${vimg%/*}"


if is_vm_exist "$VNM"; then
    do_vm_off "$VNM" || exit_s "Rejected VM shutdown"
    case "$ARGS" in
-d|-c) VBoxManage unregistervm "${VNM}" ;; #--delete
   -m) printf "VM exist, updating settings!\n" ;;
    *) exit_s "\n!!! ERR: There are already such VM: ${VNM} !!!\n";
esac; else case "$ARGS" in
   -m) exit_s "There no such VM as '${VNM}'"
esac; fi

# =======================================================================


if [[ ! -f "${vbox?No}" ]]; then
    VBoxManage createvm --name "${VNM}" --ostype "$ost" --basefolder "${VMs?No}" --register

    # FIXME: do it only once!
    # Add host-only network in Host vbox and check it:
    if ! VBoxManage list -l hostonlyifs | grep -q "${VBOX_NET?No}"; then
        VBoxManage hostonlyif create
        VBoxManage dhcpserver add --ifname "$VBOX_NET" --enable
        ifconfig "$VBOX_NET"
    fi

    VBoxManage modifyvm "${VNM}" $(for k in "${!VMOPTS[@]}"
        do printf "%s %s" "--$k" "${VMOPTS[$k]}"; done)

    add_port_forward "${VNM}" "${VNM}_ssh" "tcp,,${VBOX_PORT?No},,22"

    # Provide virtual serial port to debug guest kernel
    #   Install Arch from serial port:  https://wiki.archlinux.org/index.php/Working_with_the_serial_console
    VBoxManage modifyvm "${VNM}" --uart1 0x3F8 4 --uartmode1 server "${SERIAL?No}"

    # Only if Extensions installed
    # --usbehci on
    # --defaultfrontend default|<name>

    sed -i '/ShowMiniToolBar/ s/\(value="\)\w\+"/\1no"/' "$vbox"
fi

# =======================================================================


if [[ ! -f "$vimg" ]]; then
    if [[ $(cat /sys/block/sda/queue/rotational) -eq 0 ]]
    then HDDOPTS="--nonrotational on"; fi  # Only for SSD

    VBoxManage storagectl "${VNM}" --name "IDE" --add ide \
        --controller PIIX4 --hostiocache on --bootable on
    VBoxManage storageattach "${VNM}" --storagectl "IDE" \
        --port 0 --device 0 --type dvddrive --medium "${install_iso?No *.iso to install}"

    VBoxManage createhd --filename "$vimg" \
        --size ${VBOX_HDD?No} --format VDI --variant Standard
    VBoxManage storagectl "${VNM}" --name "SATA" --add sata \
        --controller IntelAHCI --hostiocache on --portcount 1
    VBoxManage storageattach "${VNM}" --storagectl "SATA" \
        --port 0 --device 0 --type hdd $HDDOPTS --medium "$vimg"
fi

echo "W: vbox '${VNM}' vm"
