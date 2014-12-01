#!/bin/bash
source ~/.bash/functions
amScriptDir -s
if [ -z "$SCRIPT_DIR" ]; then echo "Error: SCRIPT_DIR"; exit 1; fi

CONF_DIR="${SCRIPT_DIR%/*}/cfg"

lnLst()
{   # 1 - dstdir, 2 - srcdir, 3 - fls list
    local rlpath
    for rlpath in $3; do
        pairLink "${1}${rlpath##*/}" "${CONF_DIR}/${2}${rlpath}"
    done
}

if [ "$CURR_PLTF" == "Linux" ]
then
    lnLst ~/. "" "bash i3 urxvt Xrc mutt"
    lnLst ~/. bash/ "inputrc profile bashrc bash_prompt tmux.conf zsh/zshrc"
    lnLst ~/. "" "vim vim/vimrc vim/ycm_extra_conf.py"
    lnLst ~/.config/ "" "ranger mcomix sxiv"
    lnLst ~/.mpv/ mpv/ "config input.conf"
    lnLst ~/.config/copyq/ Win/ "copyq.conf"
    lnLst ~/.config/gtk-3.0/ sets/ "settings.ini"
    lnLst ~/. sets/ "gtkrc-2.0 wgetrc dhexrc" #valgrindrc

    if [ "$CURR_PROF" == "home" ]; then
        pairLink ~/.mpd/mpd.conf "${CONF_DIR}/sets/mpd-sir.conf"
    else
        pairLink ~/.mpd/mpd.conf "${CONF_DIR}/sets/mpd-own.conf"
    fi

    pairLink ~/.bin "${CONF_DIR}/../bin"
    pairLink ~/.dircolors "${CONF_DIR}/bash/dircolors.256dark"
    pairLink ~/.ncmpcpp/config "${CONF_DIR}/sets/ncmpcpp.conf"
    pairLink ~/.ncmpcpp/keys "${CONF_DIR}/sets/ncmpcpp.keys"
    pairLink ~/.w3m/config "${CONF_DIR}/w3m/config"
    pairLink ~/.w3m/keymap "${CONF_DIR}/w3m/keymap"
    pairLink ~/.pentadactylrc "${CONF_DIR}/Win/pentadactylrc"

    pairLink ~/.config/dunst/dunstrc "${CONF_DIR}/Xrc/dunstrc"
fi

if [ "$CURR_PLTF" == "MINGW" ]
then
    prtb="d:\Portable"
    [ ! -d "$prtb" ] && prtb="d:\PR Portable"
    if [ -d "$prtb" ]; then
        pairLink "${prtb}\Demons\windowspager\windowspager.ini" "${CONF_DIR}\Win\windowspager.ini"
        pairLink "${prtb}\Demons\CopyQ\config\copyq\copyq.conf" "${CONF_DIR}\Win\copyq.conf"
    fi

    pairLink "${HOME}\_pentadactylrc" "${CONF_DIR}\Win\pentadactylrc"
    pairLink "${HOME}\.vim" "${CONF_DIR}\vim"
    pairLink "${HOME}\.vimrc" "${CONF_DIR}\vim\vimrc"

    # Wacom drawing tablet
    WACOM_DAT=$(win2unix "c:\Users\Amer\AppData\Roaming\WTablet\Wacom_Tablet.dat")
    if [ -f "$WACOM_DAT" ]; then
        cp -f "${CONF_DIR}/Win/Wacom_Tablet.dat" "$WACOM_DAT"
    fi
fi

