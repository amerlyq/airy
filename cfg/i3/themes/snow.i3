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
green='#60ff60'

wndtheme="
# font -misc-fixed-medium-r-normal--13-120-75-75-C-70-iso10646-1
# font pango:PragmataPro 8
font pango:Ubuntu 9
# class                 border  bkgrnd. text    indicator
client.focused          #88ff88 #40dd40 $dark   #ff4500
client.focused_inactive #ffff44 #ffffbb $dark   #ff4500
client.unfocused        $gray   $white  $gray   #ff4500
client.urgent           #ffff88 #dd4040 $white  #ff4500
"

bartheme="
    font -misc-fixed-medium-r-normal--12-120-75-75-C-70-iso10646-1
    # font pango:PragmataPro 10
    # font pango:Ubuntu 9
    colors {
        background          $white
        statusline          $dark
        separator           $gray

        # colorclass      <border> <bkgrnd> <text>
        focused_workspace  #005533 $green  $dark
        active_workspace   #333333 #5f676a $dark
        inactive_workspace #777777 #dddddd $dark
        urgent_workspace   #900000 #FFD700 $dark
    }
"

