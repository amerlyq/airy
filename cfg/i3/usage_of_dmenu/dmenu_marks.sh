#!/bin/bash
# Simple i3wm mark/goto function thrue dmenu and i3-msg
#   bindsym $mod+m exec ~/.i3/scripts/dmenu_marks.sh mark
#   bindsym $mod+g exec ~/.i3/scripts/dmenu_marks.sh goto
# Modified: 27.10.2011 : mseed : http://www.fastlinux.eu

DMENU='dmenu -i -b -nb #000000 -nf #999999 -sb #000000 -sf #31658C -fn -misc-fixed-medium-r-normal-*-*-200-75-75-*-*-iso8859-2'

if [ "$1" == "mark" ]; then
    CMD=`$DMENU -p "MARK:" <<< "$name"`
    i3-msg mark $CMD

elif [ "$1" == "goto" ]; then
    MARKS=`i3-msg -t get_marks | sed -e 's/,/\n/g' -e 's/"//g' -e 's/\[//g' -e 's/\]//g' | $DMENU -p "GOTO:"`
    i3-msg [con_mark=\"$MARKS\"] focus

fi
