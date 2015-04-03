#!/usr/bin/env bash
source ~/.bash/functions.d/vbox && amScriptDir || exit $?
cd "$SCRIPT_DIR"
if [ -z "$1" ]; then squit "Need option"; fi

./vbox-create.sh $1

VNM="Arch64"

do_vm_run "$VNM"

