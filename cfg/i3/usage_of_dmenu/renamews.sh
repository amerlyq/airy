#!/usr/bin/sh

current_name=$(i3-msg message -t get_workspaces | grep -o '[1234567890]*,"name":"[^"]*","visible":true,"focused":true' | cut -d, -f1)

dmenu_result=$(cat /dev/null | dmenu -f -z -i -fn 'Droid Sans Mono-9:normal' -nb '#333333' -nf '#dedede' -sb '#a2bdbb' -sf '#333333' -p "Rename workspace to ${current_name}:")

if [ -z $dmenu_result ]
then i3-msg "rename workspace to \"$current_name\""
else i3-msg "rename workspace to \"$current_name: $dmenu_result\""
fi

