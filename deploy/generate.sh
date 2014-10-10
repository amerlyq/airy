#!/bin/bash
source ~/.bash_export
source ~/.bash_functions
amScriptDir -s
if [ -z "$SCRIPT_DIR" ]; then echo "Error: SCRIPT_DIR"; exit 1; fi

GENS="$SCRIPT_DIR/generate.d"

if [ "${CURR_PLTF}" == "Linux" ]; then
    "$GENS/xsessionrc.gen"
    "$GENS/xresources.gen"
    "$GENS/synergy.gen"
fi
