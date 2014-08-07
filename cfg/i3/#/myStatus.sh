#!/bin/sh

#----------------------------------------------------------
# file:     $HOME/.bin/myStatus.sh
# autor:    Nurlan Sadikov
# modified: Oktober 2013
#----------------------------------------------------------

#----------------------------
# Dzen settings & Variables
#----------------------------
ICON_PATH="$HOME/.dzen2/icons"
DZEN_FG="#0e6638"
DZEN_BG="#1c2b33"

H=15
W=510
X=856
Y=0
BAR_FG=""
BAR_BG=""
FONT="Ohsnap:size=8"
SLEEP=3
DZEN="dzen2 -bg $DZEN_BG -fg $DZEN_FG -fn $FONT -h $H -ta r -y $Y"

$HOME/.bin/mySystemInfo.sh | $DZEN -w $W -x $X &
conky -c $HOME/.bin/conky_lang | $DZEN -w 50 -x 600
