#!/usr/bin/env bash
source ~/.bash/functions.d/system && amScriptDir || exit $?
source "$SCRIPT_DIR/vbox-funcs" || exit $?
source "$SCRIPT_DIR/vbox-env" || exit $?  # Import some variables


hopt() { [ "${OPTS/[$1]}" != "$OPTS" ]; }
oadd() { OPTS="${OPTS}${1}"; }

case "$1" in -[rhcispe]) OPTS="${1##*-}" ;;
    *) squit "Need option -'rhcisp'" ;; esac
hopt r && { do_vm_run "$VNM" -y; squit; }
hopt h && oadd c
hopt c && oadd s
hopt s && oadd rp
hopt p && oadd i
hopt i && oadd e


#####################################################
### Create vbox and setup local repository server ###
#####################################################
hopt r && do_vm_off "$VNM" -y
hopt c && "$SCRIPT_DIR/vbox-create.sh" -c
hopt r && do_vm_run "$VNM" -y $(hopt h && echo '-h')

hopt e && [ -d "$VMs/pkg" ] && { ( cd "$VMs/pkg" &&
    python2 -m SimpleHTTPServer 23208 | tee /tmp/vbox-PackageServer.log
) & trap "kill -15 $!; exit 1" EXIT SIGINT SIGTERM; }

hopt r && do_sleep 8  # WARNING: May be facing problems with timing!

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
hopt s && do_vm_keys "$VNM" <<EOT
0f 8f 39 b9  # <Tab><Space>
2e ae 18 98 31 b1 1f 9f 18 98 26 a6 12 92         # 'console'
0d 8d 14 94 14 94 15 95 36 1f 9f b6 0b 8b 33 b3   # '=ttyS0,'
02 82 02 82 06 86 03 83 0b 8b 0b 8b 31 b1 09 89   # '115200n8'
1c 9c  # Enter
EOT

## Login and send setup files
hopt s && do_sleep 25
if hopt p; then
    do_vm_socket "$SERIAL" <<< "root"
    do_vm_socket_dir "$SERIAL" "$SCRIPT_DIR/arch"
    do_vm_socket_file "$SERIAL" ~/.ssh/id_rsa.pub
fi

# Start installation
hopt p && do_vm_socket "$SERIAL" <<EOT
chmod u+x ~/arch/arch-install
~/arch/arch-install --new  #$(hopt i && echo --new)
# [ -n "$(hopt i && echo i)" ] && poweroff || printf "\x04"  # 04=EOT
EOT


#####################################################
###             Post-install actions              ###
#####################################################
# Non-interactive monitoring of installation (safe Ctrl-C to interrupt)
hopt p && nc -d -U "$SERIAL" | tee "${SERIAL}.log"
hopt r && wait ${VBOX_PID?No vbox pid}

if hopt c; then
## Unmount archiso from vbox and make snapshot
VBoxManage storageattach "$VNM" --storagectl "IDE" --port 0 --device 0 --medium emptydrive
VBoxManage snapshot "$VNM" take "console-base" \
    --description "Initial state with only 'base' packages installed"
fi
