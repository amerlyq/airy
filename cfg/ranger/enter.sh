#!/bin/bash
# About 'file' command
#   https://www.ibm.com/developerworks/community/blogs/58e72888-6340-46ac-b488-d31aa4058e9c/entry/get_over_extensions_use_file_command_to_determine_file_types_in_linux?lang=en

NM="$1"
EXT="${NM##*.}"
TYPE=$(file -i "$NM" | sed 's/.*:\s*\(\S*\);\s.*/\1/;q')

pause() { read -p "<======== Press ENTER to continue ========>" tmp; }

# Executables
if [ "${TYPE:0:6}" == 'text/x' ]; then
    "$PWD/$NM" && pause
    exit
fi

if [ "${TYPE:0:13}" == 'application/x' ]; then
    "$PWD/$NM" || pause
    exit
fi

# Processors
case "$EXT" in
    sh) "$PWD/$NM" && pause ;;
    py) python "$PWD/$NM" && pause ;;
    dot) dot -Tx11 "$NM"     ;;
esac

if [ $? -ne 0 ]; then pause; fi
