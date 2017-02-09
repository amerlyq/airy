#!/usr/bin/env bash
source ~/.shell/func.d/system || exit
cd $(dirname $(readlink -m ${0}))
SCRIPT_DIR="$PWD"
source ./vbox/hosts || exit  # Import some variables
source ./vbox/funcs || exit
source ./vbox/options || exit

### Options chooser ###
hlst=rhcispetl
case "$1" in
    -[$hlst]) OPTS="-${1##*-}" ;;
    +[$hlst]*) echo "::: no chain -- choosen options only :::"
        OPTS="${1##*+}" ;;
    *) exit_s "Need option -/+'$hlist'" ;; esac
# hopt r && { do_vm_run "$VNM" -y; exit_s; }
if hopt -; then
    hopt h && oadd ctx # hidden -> create, shutdown, detach/snapshot
    hopt c && oadd s   # create -> serial, login
    hopt s && oadd rp  # serial -> run, push
    hopt p && oadd i   # push -> install
    hopt i && oadd e   # install -> cache
fi

#####################################################
### Create vbox and setup local repository server ###
#####################################################
hopt r && do_vm_off "$VNM" -y
# hopt c && "$SCRIPT_DIR/vbox/create.sh" -c
hopt r && do_vm_run "$VNM" -y $(hopt h && echo '-h')

# hopt e && [ -d "$VMs/pkg" ] && { ( cd "$VMs/pkg" &&
#     python2 -m SimpleHTTPServer 23208 >/tmp/vbox-PackageServer.log 2>&1
# ) & trap "kill -15 $!; exit 1" EXIT SIGINT SIGTERM; }

# hopt r && do_sleep 8  # WARNING: May be facing problems with timing!


#####################################################
###           Booting into Live-CD                ###
#####################################################
#=>  Press <Tab> to edit boot string, add 'console=ttyS0', press <Enter>
hopt s && do_vm_keys "$VNM" <<EOTKEYS
0f 8f 39 b9  # <Tab><Space>
2e ae 18 98 31 b1 1f 9f 18 98 26 a6 12 92         # 'console'
0d 8d 14 94 14 94 15 95 36 1f 9f b6 0b 8b 33 b3   # '=ttyS0,'
02 82 02 82 06 86 03 83 0b 8b 0b 8b 31 b1 09 89   # '115200n8'
1c 9c  # Enter
EOTKEYS

## Login and send setup files
hopt s && do_sleep 25 && do_vm_socket "$SERIAL" <<< "root"
# WARNING: currently don't works
if hopt l; then
    do_vm_socket "$SERIAL" <<< "tester";
    do_vm_socket "$SERIAL" <<< "tester";
fi
if hopt p; then
    do_vm_socket_copy "$SERIAL" "$SCRIPT_DIR/arch"
    do_vm_socket_copy "$SERIAL" ~/.ssh/id_rsa.pub
fi

# Start installation
hopt i && do_vm_socket "$SERIAL" <<EOTINSTALL
chmod u+x ~/arch/arch-install
$(hopt i && echo "~/arch/arch-install -c")
$(hopt t && echo "poweroff")
EOTINSTALL


#####################################################
###             Post-install actions              ###
#####################################################
# Non-interactive monitoring of installation (safe Ctrl-C to interrupt)
hopt p && nc -d -U "$SERIAL" | tee "${SERIAL}.log"
hopt r && wait ${VBOX_PID:?}

if hopt x; then
## Unmount archiso from vbox and make snapshot
VBoxManage storageattach "$VNM" --storagectl "IDE" --port 0 --device 0 --medium emptydrive
VBoxManage snapshot "$VNM" take "console-base" \
    --description "Initial state with only 'base' packages installed"
fi
