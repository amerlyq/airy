#!/bin/bash
#   bindsym $mod+q exec ~/.i3/scripts/dmenu_session.sh
# Show session menu

DMENU='dmenu -i -b -nb #000000 -nf #999999 -sb #000000 -sf #31658C -fn -misc-fixed-medium-r-normal-*-*-200-75-75-*-*-iso8859-2'

choice=$(echo -e "lock\nlogout\nsuspend\nreboot\nshutdown" | $DMENU)

case "$choice" in
  lock) i3lock -c 000000 -i ~/.i3/images/login.png & ;;
  logout) i3-msg exit & ;;
  suspend) sudo pm-suspend & ;;
  reboot) sudo /sbin/reboot & ;;
  shutdown) sudo /sbin/poweroff & ;;
esac
