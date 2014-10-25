source ~/.bash/functions

PATH="/c/Program Files/Oracle/VirtualBox:$PATH"

VNM="Lubuntu"

if ! VBoxManage list vms | grep "\<${VNM}\>"; then
    echo "There no such VM as '${VNM}'"; squit;
fi

if VBoxManage list runningvms | grep -q "\<${VNM}\>"; then
    echo "Do you want shutdown VM='${VNM}'? (y/n)";
    read answer
    case $answer in
        [yY] | [yY][Ee][Ss] ) ;;
        [nN] | [n|N][O|o] ) echo "Rejected"; squit; ;;
        *) echo "Invalid input"; squit; ;;
    esac
    VBoxManage controlvm "${VNM}" poweroff

else
    echo "Launch VM='${VNM}' is your wish? (y/n)";
    read answer
    case $answer in
        [yY] | [yY][Ee][Ss] ) ;;
        [nN] | [n|N][O|o] ) echo "Rejected"; squit; ;;
        *) echo "Invalid input"; squit; ;;
    esac
    VBoxManage startvm "${VNM}" --type headless # --vrde off
fi

amPause
