#!/bin/bash
source ~/.shell/profile
source ~/.shell/funcs
amScriptDir -s
if [ -z "$SCRIPT_DIR" ]; then echo "Error: SCRIPT_DIR"; exit 1; fi

CONF_DIR="${SCRIPT_DIR%/*}/cfg"
THEME="${1:-${CURR_THEME:-dark}}"

lnLst()
{   # 1 - dstdir, 2 - srcdir, 3 - fls list
    local rlpath
    for rlpath in $3; do
        pairLink "${1}${rlpath##*/}" "${CONF_DIR}/${2}${rlpath}"
    done
}


if [ "$CURR_PLTF" == "MINGW" ]
then
    prtb="d:\Portable"
    [ ! -d "$prtb" ] && prtb="d:\PR Portable"
    if [ -d "$prtb" ]; then
        pairLink "${prtb}\Demons\windowspager\windowspager.ini" "${CONF_DIR}\Win\windowspager.ini"
        pairLink "${prtb}\Demons\CopyQ\config\copyq\copyq.conf" "${CONF_DIR}\Win\copyq.conf"
    fi

    pairLink "${HOME}\_pentadactylrc" "${CONF_DIR}\browser\firefox\pentadactylrc"
    pairLink "${HOME}\.vim" "${CONF_DIR}\vim"
    pairLink "${HOME}\.vimrc" "${CONF_DIR}\vim\vimrc"

    # Wacom drawing tablet
    WACOM_DAT=$(win2unix "c:\Users\Amer\AppData\Roaming\WTablet\Wacom_Tablet.dat")
    if [ -f "$WACOM_DAT" ]; then
        cp -f "${CONF_DIR}/Win/Wacom_Tablet.dat" "$WACOM_DAT"
    fi
fi

