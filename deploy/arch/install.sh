#!/usr/bin/env bash
source ~/.bash/functions.d/vbox && amScriptDir || exit $?
source "$SCRIPT_DIR/vbox-env" || exit $?  # Import some variables

case "$1" in
-n) oNew="" ;;
-r) oNew="$1" ;;
-g) do_vm_run "$VNM" -y; squit ;;
 *) squit "Need option '-r' or '-n'" ;;
esac

#####################################################
### Create vbox and setup local repository server ###
#####################################################
do_vm_off "$VNM" -y
[ -n "$oNew" ] && "$SCRIPT_DIR/vbox-create.sh" $oNew
do_vm_run "$VNM" -y -h

[ -d "$VMs/pkg" ] && { ( cd "$VMs/pkg" &&
    python2 -m SimpleHTTPServer 23208
) & trap "kill $!" EXIT; }

do_sleep 8  # WARNING: May be facing problems with timing!

VBOX_USER="$(whoami)"
VBOX_IP="$(ifconfig $VBOX_NET | awk '/inet addr/{print substr($2,6)}')"
VBOX_HOST="$(uname -n)"
DHCPIP_INN="$(VBoxManage list dhcpservers | awk '/^IP:/{print $NF}')"

VBOX_SSH="${VBOX_USER}@${VBOX_IP}"
GUEST_IP="${VBOX_IP##*.}.11"


#####################################################
###           Booting into Live-CD                ###
#####################################################
#=>  Press <Tab> to edit boot string, add 'console=ttyS0', press <Enter>
do_vm_keys "$VNM" <<EOT
0f 8f 39 b9  # <Tab><Space>
2e ae 18 98 31 b1 1f 9f 18 98 26 a6 12 92         # 'console'
0d 8d 14 94 14 94 15 95 36 1f 9f b6 0b 8b 33 b3   # '=ttyS0,'
02 82 02 82 06 86 03 83 0b 8b 0b 8b 31 b1 09 89   # '115200n8'
1c 9c  # Enter
EOT

## Login and send setup files
do_sleep 25 && do_vm_socket "$SERIAL" <<< "root"
do_vm_socket_dir "$SERIAL" "$SCRIPT_DIR/arch"
do_vm_socket_file "$SERIAL" ~/.ssh/id_rsa.pub

# Start installation
do_vm_socket "$SERIAL" <<EOT
# chmod u+x ~/arch-install
# ~/arch-install ${oNew+--new}
# poweroff
EOT


#####################################################
###             Post-install actions              ###
#####################################################
# Non-interactive monitoring of installation (safe Ctrl-C to interrupt)
nc -d -U "$SERIAL" | tee "${SERIAL}.log"
wait ${VBOX_PID?No vbox pid}

## Unmount archiso from vbox and make snapshot
VBoxManage storageattach "$VNM" --storagectl "IDE" --port 0 --device 0 --medium emptydrive
VBoxManage snapshot "$VNM" take "console-base" \
    --description "Initial state with only 'base' packages installed"
