#!/usr/bin/sh

current_name=$(i3-msg message -t get_workspaces | grep -o '[1234567890]*,"name":"[^"]*","visible":true,"focused":true' | cut -d, -f2)
current_num=$(i3-msg message -t get_workspaces | grep -o '[1234567890]*,"name":"[^"]*","visible":true,"focused":true' | cut -d, -f1)

len=${#current_name}

if [ "$len" -eq "10" ]
then i3-msg "rename workspace to \"$current_num: $1\""
fi

