#!/usr/bin/env bash
source ~/.bash/functions && amScriptDir || exit $?

cd "$SCRIPT_DIR"

./vbox-create.sh -r

VNM="Arch64"
if ! VBoxManage list vms | grep "\<${VNM}\>"; then
    squit "There no such VM as '${VNM}'"
fi

ask_confirm() {
    read answer
    case $answer in
        [yY] | [yY][Ee][Ss] ) return 0 ;;
        [nN] | [n|N][O|o] ) squit "Rejected" ;;
        *) squit "Invalid input" ;;
    esac
}

if VBoxManage list runningvms | grep -q "\<${VNM}\>"; then
    if ask_confirm "Do you want shutdown VM='${VNM}'? (y/n)"; then
        VBoxManage controlvm "${VNM}" poweroff
    fi
else
    if ask_confirm "Launch VM='${VNM}' is your wish? (y/n)"; then
        VBoxManage startvm "${VNM}" #--type headless # --vrde off
    fi
fi


