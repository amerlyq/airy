# vim: ft=sh

#####  Colors #####
 cbg1='#060d0d'
 cbg2='#313131'
fore1='#338b78'
fore2='#00372a'
bright='#a0a0a0'

white='#ffffff'
 dark='#212121'
 gray='#aaaaaa'

wndtheme="
font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1
font pango:Ubuntu 9
# class                 border  backgr. text    indicator
client.focused          #3cb371 #008080 #ffffff #ff4500
client.focused_inactive #333333 #5f676a #ffffff #292d2e
client.unfocused        #333333 #222222 #888888 #d2691e
client.urgent           #2f343a #900000 #ffffff #900000
"

bartheme="
    font -misc-fixed-medium-r-normal--12-120-75-75-C-70-iso10646-1
    #font pango:DejaVu Sans Mono 10
    colors {
        background          $white
        statusline          $dark
        separator           $gray

        # colorclass      <border> <bkgrnd> <text>
        focused_workspace  #005533 #60ff60 $dark
        active_workspace   #333333 #5f676a $dark
        inactive_workspace #777777 #dddddd $dark
        urgent_workspace   #900000 #FFD700 $dark
    }
"

