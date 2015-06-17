#!/bin/bash
source ~/.shell/profile
source ~/.shell/funcs
amScriptDir -s
if [ -z "$SCRIPT_DIR" ]; then echo "Error: SCRIPT_DIR"; exit 1; fi

GENS="$SCRIPT_DIR/generate.d"


if [ "${CURR_PLTF}" == "Linux" ]; then
    "$GENS/ssh_config.gen"
    "$GENS/xsessionrc.gen"
    "$GENS/synergy.gen"

    # Need sudo:
    "$GENS/rc-local.gen"
    "$GENS/hosts.gen"
fi
