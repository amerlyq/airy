#!/usr/bin/env bash
source ~/.bash/functions.d/vbox && amScriptDir || exit $?
cd "$SCRIPT_DIR"
if [ -z "$1" ]; then squit "Need remove option"; fi

# SEE:
#   https://github.com/wopfel/archlinux-setup-vb

# Make that script to export some current VBox variables here to use them!
./vbox-create.sh $1


VBOXIP="$(ifconfig vboxnet0 | awk '/inet addr/{print substr($2,6)}')"
DHCPIP_INN="$(VBoxManage list dhcpservers | awk '/^IP:/{print $NF}')"

VNM="Arch64"
SERIAL="/tmp/vbox-${VNM}S0"

do_vm_run -y "$VNM"

# Get scancodes in interactive: sudo showkey -s
#   http://www.win.tue.nl/~aeb/linux/kbd/scancodes-14.html

# WARNING: May be affected by problem with timing!
sleep 8
# Press <Tab> to edit boot string, add 'console=ttyS0', then <Enter>
VBoxManage controlvm "$VNM" keyboardputscancode 0f 8f 39 b9  # <Tab><Space>
VBoxManage controlvm "$VNM" keyboardputscancode 2e ae 18 98 31 b1 1f 9f 18 98 26 a6 12 92  # 'console'
VBoxManage controlvm "$VNM" keyboardputscancode 0d 8d 14 94 14 94 15 95 36 1f 9f b6 0b 8b  # '=ttyS0'
VBoxManage controlvm "$VNM" keyboardputscancode 1c 9c  # Enter

# TODO: Think how to duplicate input/output from ttyS0 and tty0 showed on monitor.

sleep 25
### Send commands:
printf "root\n" | nc -q 2 -U "$SERIAL"                           # Login
printf "\n"'cat - <<-'"'EOFARCHSETUP' > ~/arch-setup\n" | nc -U "$SERIAL"  # Send as heredoc
cat "$SCRIPT_DIR/arch-setup" | nc -U "$SERIAL"                   # Send text content of setup file
printf "\nEOFARCHSETUP\n" | nc -U "$SERIAL"                      # End of heredoc file

printf "\nchmod u+x ~/arch-setup\n" | nc -U "$SERIAL"      # Make executable
printf "\ncd ~ && ./arch-setup --new\n" | nc -U "$SERIAL"  # Start install
nc -d -U "$SERIAL"  # Non-interactive monitoring of installation (safe Ctrl-C to interrupt)
# ERROR: you must enter root password! How? Extract it from script and lauch interactive separately?
# TODO: reboot after all

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

## First state after boot
# VBoxManage controlvm <vm> savestate


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
