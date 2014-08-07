#!/bin/sh

#----------------------------------------------------------
# file:     $HOME/.bin/mySystemInfo.sh
# autor:    Nurlan Sadikov
# modified: Oktober 2013
#----------------------------------------------------------

#----------------------------
# Dzen settings & Variables
#----------------------------
ICON_PATH="$HOME/.dzen2/icons"
COLOR_ICON="#bdab1b"
CRIT_COLOR="#b2182d"
DZEN_FG="#0e6638"
DZEN_BG="#1c2b33"

SIMPL_COLOR="#6c8c84"
ATTENTION_COLOR="#bdab1b"

H=15
W=510
X=856
Y=0
BAR_FG=""
BAR_BG=""
FONT="Ohsnap:size=8"
SLEEP=3
DZEN="dzen2 -bg $DZEN_BG -fg $DZEN_FG -fn $FONT -w $W -h $H -ta r -x $X -y $Y"

# -------------
# Infinite loop
# -------------
while :; do
#sleep ${SLEEP}

# ---------
# Functions
# ---------

Mem ()
{
    MEM=$(free -m | grep '-' | awk '{print $3}')
    echo -n "mem^fg($SIMPL_COLOR)${MEM}^fg()Mb"
    return
}

Temp ()
{
    TEMP=$(acpi -t | awk '$9=substr($4,1,2) {print $9}' )
        if [[ ${TEMP} -gt 63 ]] ; then
            echo -n "temp^fg($CRIT_COLOR)${TEMP}°^fg()C"
        else
            if [[ ${TEMP} -gt 52 ]] ; then
                echo -n "temp^fg($ATTENTION_COLOR)${TEMP}°^fg()C"
            else
                echo -n "temp^fg($SIMPL_COLOR)${TEMP}°^fg()C"
            fi
        fi
    return
}

Date ()
{
    TIME=$(date +%R)
    echo -n "time^fg($ATTENTION_COLOR)${TIME} "
    return
}

Between ()
{
    echo -n " ^fg($DZEN_FG)<^fg($SIMPL_COLOR)<^fg($ATTENTION_COLOR)<^fg() "
    return
}

Battery ()
{
    PERCENT=$(acpi | awk '$9=substr($4,1,match($4,"%")-1) {print $9}')
    CHARGING=$(acpi | awk '$9=substr($3,1,1) {print $9}')
    if [[ $CHARGING == C ]] ; then
        COLOR=$SIMPL_COLOR
    else
        if [[ $PERCENT -le 12 ]] ; then
            COLOR=$CRIT_COLOR
        else
            if [[ $PERCENT -le 57 ]] ; then
                COLOR=$ATTENTION_COLOR
            else
                COLOR=$SIMPL_COLOR
            fi
        fi
    fi
    HOURS=$(acpi | awk '$9=substr($5,1,2) {print $9}')
    MINUTS=$(acpi | awk '$9=substr($5,4,2) {print $9}')
    if [[ $HOURS -eq "" ]] ; then
        if [[ $MINUTS -eq "" ]] ; then
            echo -n "bat^fg($COLOR)$PERCENT%^fg()"
        else
            echo -n "bat^fg($COLOR)$HOURS'$MINUTS^fg()'$PERCENT%"
        fi
    else
        echo -n "bat^fg($COLOR)$HOURS'$MINUTS^fg()'$PERCENT%"
    fi
    return
}



Wifi ()
{
    NAME=$(iwconfig wlp3s0 | grep 'ESSID' | awk '$9=substr($4,7,3) {print $9}')
    if [[ $NAME -eq "off" ]] ; then
        echo -n "wifi^fg($CRIT_COLOR)Off^fg()"
    else
        echo -n "wifi^fg($SIMPL_COLOR)On^fg()"
    fi
}

Month ()
{
    DAY_WEEK=$(date -R | awk '{print $1}')
    NUMBER=$(date +%d)
    MONTH=$(date -R | awk '{print $3}')
    echo -n "$DAY_WEEK^fg($SIMPL_COLOR)$NUMBER^fg()$MONTH"
}


# -----
# Print
# -----
Print () {
    Between
    Temp
    Between
    Wifi
    Between
    Battery
    Between
    Mem
    Between
    Month
    Between
    Date
    echo
    return
}
sleep ${SLEEP}
echo "$(Print)"
done
