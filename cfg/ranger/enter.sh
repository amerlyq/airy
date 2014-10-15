#!/bin/bash
# About 'file' command
#   https://www.ibm.com/developerworks/community/blogs/58e72888-6340-46ac-b488-d31aa4058e9c/entry/get_over_extensions_use_file_command_to_determine_file_types_in_linux?lang=en

NM="$1"
EXT="${NM##*.}"
TYPE=$(file -i "$NM" | sed 's/.*:\s*\(\S*\);\s.*/\1/;q')

pause() { read -p "<======== Press ENTER to continue ========>" tmp; }

# Executables
if [ "$EXT" == 'sh' ] || [ "$TYPE" == 'text/x-shellscript' ]; then
    "$PWD/$NM" && pause
fi

# Processors
case "$EXT" in
    dot) dot -Tx11 "$NM" ;;
esac

if [ $? -ne 0 ]; then pause; fi
