#!/usr/bin/env bash
source ~/.bash/functions.d/vbox && amScriptDir || exit $?
cd "$SCRIPT_DIR"
if [ -z "$1" ]; then squit "Need option"; fi

# SEE:
#   https://github.com/wopfel/archlinux-setup-vb

./vbox-create.sh $1

VNM="Arch64"

do_vm_run -y "$VNM"

# Problem with timing
# sleep 5
# VBoxManage controlvm "$VNM" keyboardputscancode 1c 9c  # Enter
# sleep 15
# VBoxManage controlvm "$VNM" keyboardputscancode 73 63 70  # scp

## First state after boot
# VBoxManage controlvm <vm> savestate


# ALT: Vagrant
#   https://lwn.net/Articles/486319/
# Keypresses
#   http://welinux.ru/post/6322/
# Sikuli -- gui automation
#   http://www.jedi.be/blog/2010/08/29/sending-keystrokes-to-your-virtual-machines-using-X-vnc-rdp-or-native/
