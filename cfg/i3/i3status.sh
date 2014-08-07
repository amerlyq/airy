#!/bin/bash

i3status --config ~/.i3/i3status.conf | while :
do
    read line
    #LG=$(setxkbmap -query | awk '/layout/{print toupper($2)}')
    LG=$(xkb-switch -p | awk '{print toupper($1)}')
    case "$LG" in
        US) dat="#00AE00" ;;
        RU) dat="#00AEFF" ;;
        UA) dat="#FFFF00" ;;
         *) dat="#C60101"
    esac
    TXT="[{ \"full_text\": \"$LG\", \"color\":\"$dat\" },"
    echo "${line/[/$TXT}" || exit 1
done
