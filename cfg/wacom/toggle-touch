#!/bin/bash

## Get the "Device name" or ID number
## for touch from 'xsetwacom list dev'

DEVICE=`xsetwacom list dev | grep -E -o ".*touch"` 
TOUCH_STATE=`xsetwacom get "$DEVICE" touch`
if [ "$TOUCH_STATE" == "on" ]
  then
    notify-send "Touch is ON, turning OFF."
    xsetwacom set "$DEVICE" touch off
  else
    notify-send "Touch is OFF, turning ON."
    xsetwacom set "$DEVICE" touch on
fi
