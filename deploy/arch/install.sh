#!/usr/bin/env bash
source ~/.bash/functions.d/vbox && amScriptDir || exit $?
source "$SCRIPT_DIR/vbox-env" || exit $?  # Import some variables

case "$1" in
-n) oNew="" ;;
-r) oNew="$1" ;;
-g) do_vm_run "$VNM" -y; squit ;;
 *) squit "Need option '-r' or '-n'" ;;
esac

do_vm_off "$VNM" -y
[ -n "$oNew" ] && "$SCRIPT_DIR/vbox-create.sh" $oNew
do_vm_run "$VNM" -y -h
do_sleep 8

VBOXIP="$(ifconfig $VBOX_NET | awk '/inet addr/{print substr($2,6)}')"
DHCPIP_INN="$(VBoxManage list dhcpservers | awk '/^IP:/{print $NF}')"

# :=  Press <Tab> to edit boot string, add 'console=ttyS0', then <Enter>
# WARNING: May be affected by problem with timing!
do_vm_keys "$VNM" << EOT
0f 8f 39 b9  # <Tab><Space>
2e ae 18 98 31 b1 1f 9f 18 98 26 a6 12 92  # 'console'
0d 8d 14 94 14 94 15 95 36 1f 9f b6 0b 8b  # '=ttyS0'
33 b3 02 82 02 82 06 86 03 83 0b 8b 0b 8b 31 b1 09 89  # ',115200n8'
1c 9c  # Enter
EOT

# NOTE: Get scancodes interactively: sudo showkey -s
#   http://www.win.tue.nl/~aeb/linux/kbd/scancodes-14.html
# TODO: Think how to duplicate input/output from ttyS0 and tty0 showed on monitor.
# >>> It simply don't work!
# NOTE: tty0 don't work and tty1 used for autologin
# 0f 8f 39 b9  # <Tab><Space>
# 2e ae 18 98 31 b1 1f 9f 18 98 26 a6 12 92  # 'console'
# 0d 8d 14 94 14 94 15 95 03 83              # '=tty2'


## Login
do_sleep 25 && do_vm_socket "$SERIAL" <<< "root"
# Send setup files
for fl in "$SCRIPT_DIR"/arch/*; do do_vm_socket_file "$SERIAL" "$fl"; done

# Start installation
do_vm_socket "$SERIAL" << EOT
cd ~
chmod u+x ./install
./install ${oNew+--new}
poweroff
EOT

nc -d -U "$SERIAL" | tee "${SERIAL}.log"
wait $VBOX_PID
# Non-interactive monitoring of installation (safe Ctrl-C to interrupt)
# nc -U "$SERIAL"
# nc -d -U "$SERIAL" #| awk '/^::: install complete :::$/{exit}'
# Shutdown after all
# do_vm_socket "$SERIAL" <<< "poweroff"

# do_sleep 2
## Unmount archiso from vbox and disable sata for it
VBoxManage storageattach "$VNM" --storagectl "IDE" --port 0 --device 0 --medium emptydrive
VBoxManage snapshot "$VNM" take "console-base" \
    --description "Initial state with only 'base' package installed"


# Netcat
#   http://www.debian-administration.org/article/58/Netcat_The_TCP/IP_Swiss_army_knife
#   http://www.debian-administration.org/article/145/use_and_abuse_of_pipes_with_audio_data
# Possible manual commands from separate terminal:
#   echo ls | nc -q 1 -U $SERIAL -P root -
#   { printf "ls\n"; sleep 0.2; } | nc -q 0 -U /tmp/vbox-"$VNM"S0 -P root -
#   cat <file> | nc -q 1 -U /tmp/vbox-"$VNM"S0 -P root -

# Fixed IP
#   http://coding4streetcred.com/blog/post/VirtualBox-Configuring-Static-IPs-for-VMs
#   http://coding4streetcred.com/blog/post/VirtualBox-Getting-Around-an-Absence-of-Domain
# ALT: use 'arp' to get MACs from vbox dhcp server, then identify IP of each guest by it's MAC
# ALT: get host names? How? How synergy does it?
# Crossplatform  ==  Linux + Windows + Geanymotion (Android)


# Setup static ip for guests' Host-only network
# cat - <<EOT >> /etc/network/interfaces
# auto eth1
# iface eth1 inet static
# address 192.168.56.7
# netmask 255.255.255.0
# EOT
# ifup eth1
# ssh user@192.168.56.10


# Get known to host ip-mac pairs
#   arp -a
# Get guest IP:
#   Install VBoxAdditions
#   VBoxManage guestproperty enumerate Arch64
#   VBoxManage guestproperty get Arch64 "/VirtualBox/GuestInfo/Net/2/V4/IP"

# ALT: Vagrant
#   https://lwn.net/Articles/486319/
# Send binary as text over serial port to bare linux embedded device
#   http://www.devttys0.com/2011/05/serial-file-uploads-with-serio/
# BADLY e.g: https://github.com/wopfel/archlinux-setup-vb

