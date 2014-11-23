#!/bin/bash
source ~/.bash_export
source ~/.bash/functions
amScriptDir -s
if [ -z "$SCRIPT_DIR" ]; then echo "Error: SCRIPT_DIR"; exit 1; fi

GENS="$SCRIPT_DIR/generate.d"

if [ "${CURR_PLTF}" == "Linux" ]; then
    "$GENS/ssh_config.gen"
    "$GENS/xsessionrc.gen"
    "$GENS/xresources.gen"
    "$GENS/synergy.gen"


    # bash .\w aliases -> ranger/bookmarks
    ~/.config/ranger/aliases_to_bookmarks
fi
