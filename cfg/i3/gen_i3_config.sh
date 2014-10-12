#!/bin/bash
#
# You can run this script from xsessionrc before each start of i3.
# In generator -- bind colors to $vars, so you can change color themes consistently
# In generation process by specifying one var you could change themes between light and dark

source ~/.bash_functions
if [ -z "$1" ]; then
    thm_nm=grass
elif [ "$1" == "-l" ]; then
    for file in ~/.i3/themes/*.i3; do
        echo ${file##*/}
    done
    exit
else thm_nm="$1"; fi
source ~/.i3/themes/"${thm_nm}.i3"

# ----- Paths -----
dst=~/.i3/config
wbegin
wcat ~/.i3/config_base


# ---- Strings ----

# Choose appropriate terminal (get current launched v-terminal)
# Somehow works unstable, backing one level deeper to term=zsh instead of term=urxvt
#   when you launch it from install.sh and not directly
# pid=$$
# while [ "$(echo $pid)" != 1 ]; do
#     term=`ps -h -o comm -p $pid 2>/dev/null`
#     pid=`ps -h -o ppid -p $pid 2>/dev/null`
#     echo ": $term"
# done

bs="bindsym"
bm="$bs \$mod"
t="    "
ealws="exec_always --no-startup-id"
exno="exec --no-startup-id"

term=`update-alternatives --get-selections | grep 'x-terminal-emulator' | awk '{ print $3 }'`
term="${term##*/}"

if [ "$term" == "urxvtd" ]; then
    term="urxvt"
    # Many times inside tmux demon was hanged, so it's better use separate processes
    #eurx="$exno urxvtcd"
    eurx="$exno urxvt"
else eurx="$exno $term"; fi

eflo="$eurx -name Float"
## Disabled: wnd name wrong setted in zsh only!
#ecli="$exno urxvtcd -e \$SHELL -i -c " #--hold

#For auto-hiding bar, pinned only for modes
#wk_mode()   { wstr "$bm+$1 bar mode dock; mode \"$2\""; }
#mdf="mode \"default\"; bar mode hide; exec sleep 0.1; exec xdotool key --clearmodifiers alt"

# ---- Writers ----
w_header(){ wprf "\n### $1 ###\n"; }
wk_mode()   { wstr "$bm+$1 mode \"$2\""; }
wmode_begin(){ wk_mode "$1" "$2"; wstr "mode \"$2\" {"; }
wmode_end()  { wprf "\n$t$bs Return \$mdef \n$t$bs Escape \$mdef \n$t$bs space \$mdef \n}\n"; }


# ----- Lists -----
hjkl="h j k l"
digits="1 2 3 4 5 6 7 8 9 0"
arrows="left down up right"
Arrows="Left Down Up Right"
# wnames=( "1:main" "2:home" "3:work" "4:www" "5" "6" "7" "8" "9" "10" )
wnames=( `cat ~/.i3/names | sed '/^[0-9]\+/!d' | awk '{ print $0 }' RS='\n' ORS=' '` )
wrknum=( \$w1 \$w2 \$w3 \$w4 \$w5 \$w6 \$w7 \$w8 \$w9 \$w10 )
wrksps="${wrknum[@]}"

# ----- Vars -----
smove="50 px"

wprf "\n### =========== Script-generated items ============= ###\n"

w_header "Bind: Refresh on i3mod"

wstr "set \$mdef mode \"default\""
wstr "set \$upd ~/.i3/blocks/update"

wstr ''
wlistf "set %s %s" "$wrksps" "${wnames[@]}"

# wstr "set \$refbar bash -c 'kill -s SIGRTMIN+1 \$(pidof i3blocks)'"
# i3mod=64 #LAlt
#wstr "bindcode $i3mod $exno \$upd lang"
# key_ralt=108
# wstr "bindcode --release $key_ralt $exno \$upd lang"

wprf "\n### ================== Workspaces ================== ###\n"

M1=( `cat ~/.cache/displayside | sed 1d` )
if [ ! -z "$M1" ]; then
    if [ ${#M1[@]} -le 1 ]; then M2="${M1[0]}"; else M2="${M1[1]}"; fi
    for i in {1..5}; do monitors="$M1 $monitors $M2"; done
    w_header "WorkSpaces: Output"
    wlistf "workspace %s output %s" "$wrksps" "$monitors"
fi

w_header "WorkSpaces: Focus"
wlistf "$bm+%s workspace number %s" "$digits" "$wrksps"

w_header "WorkSpaces: Move container"
wlistp "$bm+Control+%1 move container to workspace number %2, workspace number %2" "$digits" "$wrksps"

w_header "WorkSpaces: Move container"
wlistp "$bm+Shift+%1 move container to workspace number %2" "$digits" "${wrknum[*]:0:7}"

wprf "\n### ================== Navigation ================== ###\n"
w_header "Navigation: Focus"
wlistf "$bm+%s focus %s" "$hjkl $Arrows" "$arrows $arrows"

w_header "Navigation: Move"
wlistf "$bm+Shift+%s move %s $smove" "$hjkl $Arrows" "$arrows $arrows"
## Move current floating window in certain position
# .. move absolute position 0 0


wprf "\n### ================== Mark/Goto =================== ###\n"
# keybindings for marking and jumping to clients

#bindsym $mod+Shift+F1 mark F1
#bindsym $mod+F1 [con_mark="F1"] focus
#bindsym $mod+Control+F1 unmark F1

w_header "Navigation: Mark"
wmode_begin 't' "Mark this: 0..9, Mod+T"
wprf "$t$bm+t $exno i3-input -F 'mark %%s' -P 'Mark name: ', \$mdef\n\n"
wlistf "$t$bs %s mark mrk%s, \$mdef" "$digits" "$digits"
wmode_end

w_header "Navigation: GoTo"
wmode_begin 'g' "GoTo mark: 0..9, Mod+G"
wprf "$t$bm+g $exno i3-input -F '[con_mark=%%s] focus' -P 'Go to mark: ', \$mdef\n\n"
wlistf "$t$bs %s [con_mark=\"mrk%s\"] focus, \$mdef" "$digits" "$digits"
wmode_end

# direction = <up, down, left, right, width or height>
# resize <grow|shrink> <direction> [<px> px [or <ppt> ppt]]

# Jump exactly to the next open VIM instance
wstr "$bm+v [class=\"(?i)$term\" title=\"(?i)vim\"] focus"
wstr "$bm+r [class=\"(?i)$term\" title=\"(?i)ranger\"] focus"


wprf "\n### =================== Modify ===================== ###\n"
w_header "Containers: Modify"

smoveprecise="5 px"
ssize="10 px or 2 ppt"

wmode_begin "c" "Modify"
wlistf "$t$bs %s $exno ~/.i3/ext/ratio_size %s, \$mdef" "1 2 3" \
    "0.5" "0.667" "0.75"
wstr ''
wlistf "$t$bs %s resize %s $ssize" "$hjkl" \
    "shrink right" "grow down" "shrink down" "grow right"
wstr ''
wlistf "$t$bs Shift+%s resize %s $ssize" "$hjkl" \
    "grow left" "shrink up" "grow up" "shrink left"
wstr ''
wlistf "$t$bs %s resize %s $ssize" "$Arrows" \
    "shrink width" "grow height" "shrink height" "grow width"
wstr ''
wlistf "$t$bm+%s move %s $smoveprecise" "$hjkl" "$arrows"
wstr ''
wlistf "$t$bs Shift+%s move %s $smoveprecise" "$Arrows" "$arrows"
wmode_end


wprf "\n### =================== System ===================== ###\n"
wstr "$bm+Shift+r restart"
wstr "$bm+Shift+x $exno ~/.i3/ext/i3exit lock"

w_header "Mode: System"
wstr "set \$system_mode i3: re(c)onf, re(n)ew, (e)xit || System: (l)ock, log(o)ut, (s)uspend, (h)ibernate, (r)eboot, shu(t)down"

wk_mode 'Shift+Escape' "\$system_mode"
wmode_begin 'Delete' "\$system_mode"
wlistf "$t$bs %s $exno ~/.i3/ext/i3exit %s, \$mdef" "l o s h r t" \
    "lock logout suspend hibernate reboot shutdown"

# c - reload the configuration file
# n - restart i3 inplace (preserves your layout/session, can be used to upgrade i3)
# e - logs you out of your X session
#, mode \"default\"\"
wlistf "$t$bs %s %s" "c n" "reload restart"
wstr ''
wstr "$t$bs e $exno ~/.i3/ext/i3exit logout"
wmode_end

# lock screen and suspend
#bindsym $mod+Control+s exec i3lock && dbus-send --system --print-reply --dest=org.freedesktop.UPower /org/freedesktop/UPower org.freedesktop.UPower.Suspend

wprf "\n### ================== Launchers =================== ###\n"

pcli="r v n h"
bcli="ranger vim ncmpcpp htop"
pgui="g t z w"
bgui="gvim gvim.tex zathura wuala"

# xclip -o > /tmp/xclipboard && $EDITOR /tmp/xclipboard

w_header "Mode: Open"
wmode_begin 'o' "Open: $pcli, $pgui, p l a s"
wlistf "$t$bs %s $eflo -e %s, \$mdef" "$pcli w p l" $bcli "w3m google.com" "gksudo powertop" "gksudo tlp start"
wstr ''
wstr "$t$bs m $exno ~/.i3/ext/dmenu_mpd_fmove, \$mdef"
wstr ''

# Autochoose filemng by OS version.
STD_FILEMGR="pcmanfm"
command -v $STD_FILEMGR >/dev/null 2>&1 || STD_FILEMGR="nemo --no-desktop"

#TODO: remove 's' -- <sound>.py
wlistf "$t$bs %s $exno %s, \$mdef" "$pgui a s e" $bgui "$STD_FILEMGR" "/usr/lib/cinnamon-settings/cinnamon-settings.py sound" "elona"
wmode_end

w_header "Mode: Focus"
wmode_begin 'y' "Focus: $pcli, $pgui"
wlistf "$t$bs %s [class=\"(?i)$term\" title=\"(?i)%s\"] focus, \$mdef" "$pcli" "$bcli"
wstr ''
wlistf "$t$bs %s [class=\"(?i)%s\"] focus, \$mdef" "$pgui" "$bgui"
wmode_end

# There also is the (new) i3-dmenu-desktop which only displays applications shipping a .desktop file. It is a wrapper around dmenu, so you need that installed.
# bindsym $mod+Control+d exec --no-startup-id i3-dmenu-desktop
# ALT: j4-dmenu-desktop
# set $dmenu j4-dmenu-desktop --dmenu="dmenu -f -z -i -fn 'Droid Sans Mono-9:normal' -nb '#333333' -nf '#dedede' -sb '#d64937' -sf '#dedede'"

w_header "Run: Prgs" # i3-sensible-terminal, ranger
wstr "$bm+Return $eurx"
wstr "$bm+Control+Return $eflo"
wstr "$bm+Shift+Return $eflo -e ranger-auto"

w_header "Run: Menus"
wstr "$bm+d exec \"dmenu_run -p 'yes, master?' -nb '#000000' -nf '#B0E0E6' -sb '#421C84' -sf '#FFFF00' -fn -misc-fixed-medium-r-normal-*-*-130-75-75-*-*-iso8859-2\""
wstr "$bm+u exec rofi -now -font 'Sans-10' -fg '#606060' -bg '#000000' -hlfg '#ffc964' -hlbg '#0C0C00' -o 85"
wstr "$bs Print exec scrot '%Y%m%d_%H%M%S_\$wx\$h.png' -e 'mv \$f ~/Downloads/'"
# Also: lxtask

# Those maps drop focus from input fields in browser.
# Deprecated by xkb detailed settings.
w_header "Languages"
#wlistf "$bm+Shift+%s $exno xkb-switch -s %s && \$upd lang" "0 9 8" "us ru ua"
wlistf "$bm+Shift+%s $exno dbus-send --dest=ru.gentoo.KbddService /ru/gentoo/KbddService \
     ru.gentoo.kbdd.set_layout uint32:%s && \$upd lang" "0 9 8" "0 1 2" #"us ru ua"


w_header "Autostart"
wstr "$exno auto-once"
wstr "$ealws auto-always"

#wstr "$eurx -name htop -e htop"
#wstr "for_window [class=\"(?i)$term\" instance=\"(?i)htop\"] move scratchpad"

# Also: starter, volumeicon, weechat, xscreensaver -no-splash,
# clipit, parcellite, dropbox, lxsession -s Lubuntu -e LXDE



wprf "\n### ================= Multimedia =================== ###\n"
# instead of <5% | 2dB>
# apt-get intall xbindkeys
# https://wiki.archlinux.org/index.php/Xbindkeys_(%D0%A0%D1%83%D1%81%D1%81%D

w_header "Control: touchpad on/off"
wlistf "$bm+%s $exno synclient TouchpadOff=%s" "p Shift+p" 1 0
wstr ''

#bindsym XF86AudioMicMute exec "amixer -D pulse sset Capture toggle"
#bindsym XF86TouchpadToggle exec "synclient TouchpadOff=$(synclient | awk '/TouchpadOff/ {print ($3+1)%2}')"

# Don't forget to set primary PCH to card 0 or disable all others.
w_header "Control: volume"
wlistf "$bs %s $exno amixer -q -D pulse set Master %s && \$upd volume" \
    "XF86AudioRaiseVolume XF86AudioLowerVolume XF86AudioMute" \
    '2%+ unmute' '2%- unmute' 'toggle'
wstr ''
wlistf "$bm+%s $exno amixer -q -D pulse set Master %s && \$upd volume" \
    "Home Prior Next End" \
    '20% unmute' '2%+ unmute' '2%- unmute' 'toggle'
# pactl set-sink-volume 0 -- +10%
# pactl set-sink-volume 0 -- -10%
# pactl set-sink-mute 0 toggle
# mocp -r


w_header "Control: ncmpcpp"
wlistf "$bs %s $exno ncmpcpp %s && \$upd mpd" \
    "XF86AudioPlay XF86AudioNext XF86AudioPrev XF86AudioStop" \
    "toggle next prev stop"
wstr ''
wlistf "$bm+Control+%s $exno ncmpcpp %s && \$upd mpd" \
    "Home Prior Next End" "toggle prev next stop"


wprf "\n### =================== Windows ==================== ###\n"
w_header "Windows: Settings"

wstr "assign [class=\"^Firefox$\"] \$w4"
wstr "assign [class=\"^Pale\ moon$\"] \$w4"
wstr "assign [class=\"^Wine$\"] \$w9"
wstr "assign [class=\"^Wuala$\"] \$w10"
wstr "assign [class=\"^Steam\"] \$w9"
wstr "assign [class=\"^t-engine64\"] \$w8"
wstr ''

# How to launch in floating regime? Simply create window with name starting with Float*.
# floating enable running before launching of exec, so influence on previous focused wndw
wstr "for_window [class=\"(?i)$term\" instance=\"(?i)^Float*\"] floating enable"

wstr "for_window [window_role=\"pop-up\"] floating enable"
#wstr "for_window [class=\"(?i)$term\"] border 1pixel"
#wstr "for_window [class=\"(?i)$term\" title=\"(?i)vim\"] border none"

# wlistf "for_window [class=\"(?i)%s\"] floating enable" \
#     "lxappearance copyq"
wstr "for_window [instance=\"feh\"] fullscreen"
wstr "for_window [class=\"^Conky\"] border none"
wstr "for_window [instance=\"^Download\" class=\"^Firefox\"] floating enable"
wstr "for_window [class=\"^t-engine64\"] border none"

wprf "\n### ================== Bar & Theme ================= ###\n"
# (dzen2, xmobar, maybe even gnome-panel?),
# you can just remove the i3bar configuration and start your favorite bar instead.

    # You can restrict i3bar to one or more outputs (monitors). The default is to handle all outputs.
    # Restricting the outputs is useful for using different options for different outputs by using multiple bar blocks.
    # You could specify many times 'output <output>' to duplicate in multiple monitors
    # LVDS1 - laptop, HDMI2, DP2 - DisplayPort, DFP3|DFP4
    #output            LVDS1
    #none if lxpanel
    #tray_output         primary   # <none|primary|output>

    # Needs to be generated
    # https://github.com/ultrabug/py3status
    # https://github.com/sardemff7/j4status
    #status_command conky -c ~/.i3/i3conky.conf | dzen2 -h '17' -w '600' -x '1317' -y '1062' -bg '#000000' -ta 'rm'
    #status_command conky -c ~/.i3/i3conky.conf | dzen2 -h '18' -w '600' -x '766' -y '751' -bg '#000000' -ta 'rm'
    #status_command    i3status --config ~/.i3/i3status.conf
    #status_command sh ~/bin/.conkyi3.sh

    #error: binding_mode_indicator yes
    # hide - hidden and is only unhidden in case of urgency hints or by pressing the modifier key
    # show - it is drawn on top of the currently visible workspace
    #error: hidden_state        hide    # <hide|show>


#bar hidden_state hide|show|toggle [<bar_id>]
#bar mode dock|hide|invisible|toggle [<bar_id>]
wstr "$bm+grave bar mode toggle"
wstr "$bm+Shift+grave bar mode dock"
wstr "$bm+Control+grave bar mode invisible"

#~/.i3/i3status.sh
wstr "$wndtheme
bar {
    id                  bar-main # Specifies the bar ID for the configured bar instance (if many)
    mode                dock     # <dock|hide|invisible>
    position            bottom   # <top|bottom>
    workspace_buttons   yes
    status_command      i3blocks -c ~/.i3/i3blocks.conf
    modifier            \$mod
    $bartheme}
"

echo "W: $dst"

