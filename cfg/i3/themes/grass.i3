# vim: ft=sh

# Font for window titles. Will also be used by the bar unless a different font is used in the bar {} block below. ISO 10646 = Unicode
# The font above is very space-efficient, that is, it looks good, sharp and clear in small sizes. However, if you need a lot of unicode glyphs or right-to-left text rendering, you should instead use pango for rendering and chose a FreeType font, such as:

#font pango:DejaVu Sans Mono 9
#font pango:DejaVu Sans Mono, Terminus Bold Semi-Condensed 10

#####  Colors #####
# For color-themes there is i3-style script with many themes
# https://www.npmjs.org/package/i3-style
#set $cbg1   #060D0D
#set $cbg2   #313131
#set $fore1  #338B78
#set $fore2  #00372A
#set $bright #a0a0a0
#set $white  #ACFFF9
#set $dark   #212121

#You can also specify the color to be used to paint the background of the client windows. This color will be used to paint the window on top of which the client will be rendered.
# client.background color

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
        background          #000000
        statusline          #ffffff
        separator           #555555

        # colorclass <border> <background> <text>
        focused_workspace  #00ff00 #005533 #ffffff
        active_workspace   #333333 #5f676a #ffffff
        inactive_workspace #333333 #222222 #888888
        urgent_workspace   #900000 #FFD700 #000000
    }
"

        #focused_workspace  #4c7899 #285577 #ffffff
        #active_workspace   #333333 #5f676a #ffffff
        #inactive_workspace #333333 #222222 #888888
        #urgent_workspace   #2f343a #900000 #ffffff
