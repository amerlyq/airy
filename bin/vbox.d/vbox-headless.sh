#!/usr/bin/env bash
source ~/.bash_export
source ~/.bash/functions
if [ $? -ne 0 ]; then echo "nnoo!"; exit; fi

# squit() { printf "$1\n"; [["$PS1"]]&&exit 1||return 1; }
ask_confirm() {
    read answer
    case $answer in
        [yY] | [yY][Ee][Ss] ) return 0 ;;
        [nN] | [n|N][O|o] ) squit "Rejected" ;;
        *) squit "Invalid input" ;;
    esac
}

if [ "$CURR_PLTF" == "MINGW" ]; then
    PATH="/c/Program Files/Oracle/VirtualBox:$PATH"
fi

VNM="Lubuntu"

if ! VBoxManage list vms | grep "\<${VNM}\>"; then
    squit "There no such VM as '${VNM}'"
fi

if VBoxManage list runningvms | grep -q "\<${VNM}\>"; then
    if ask_confirm "Do you want shutdown VM='${VNM}'? (y/n)"; then
        VBoxManage controlvm "${VNM}" poweroff
    fi
else
    if ask_confirm "Launch VM='${VNM}' is your wish? (y/n)"; then
        VBoxManage startvm "${VNM}" --type headless # --vrde off
    fi
fi

amPause
