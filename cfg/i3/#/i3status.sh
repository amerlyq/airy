#!/bin/bash

i3status --config ~/.i3/i3status.conf | while :
do
    read line
    #LG=$(setxkbmap -query | awk '/layout/{print toupper($2)}')
    LG=$(xkb-switch -p | sed 's/am(\(.*\))\|\(\w\+\)/\U\1\2/')
    #LG="$LG"
    case "${LG}" in
        US) dat="#00AE00" ;;
        RU) dat="#00AEFF" ;;
        UA) dat="#FFFF00" ;;
         *) dat="#C60101"
    esac

    # echo -n "mem^fg($SIMPL_COLOR)${MEM}^fg()Mb"
    # PERCENT=$(acpi | awk '$9=substr($4,1,match($4,"%")-1) {print $9}')
    # iwconfig wlan0

    mem=$( free -m | awk '$1 == "Mem:" { t=$2/100; rc=int($3/t+1) }; $1 == "-/+" { printf "♏ %d/%d%%\n",int($3/t+1),rc }' )
    c_mem="#FF9900"
    track=$( mpc status | sed -n 'N;s/^\(.*\)\n\[playing\]\s*\S*\s*\(\S*\)\s*.*/(\2) \1/p' )

    c_track="#FF00FF"
    TXT="[{
            \"full_text\": \"$track\",
            \"color\":\"$c_track\"
        },
        {
            \"full_text\": \"$LG\",
            \"color\":\"$dat\"
        },
        {
            \"full_text\": \"$mem\",
            \"color\":\"$c_mem\"
        },
        "
    echo "${line/[/$TXT}" || exit 1
done
