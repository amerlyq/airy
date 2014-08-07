#!/usr/bin/sh

dmenu_result=$(cat /dev/null | dmenu -f -z -i -fn 'Droid Sans Mono-9:normal' -nb '#333333' -nf '#dedede' -sb '#a2bdbb' -sf '#333333' -p "Go to workspace: ")

number=$(echo $dmenu_result | grep -o -E "^[1234567890]*$")

if [ -z $number ]
then i3-msg "workspace \"$dmenu_result\""
else i3-msg "workspace number \"$dmenu_result\""
fi

