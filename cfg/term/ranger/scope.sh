#!/usr/bin/env bash

# Meanings of exit codes:
# code | meaning    | action of ranger
# -----+------------+-------------------------------------------
# 0    | success    | success. display stdout as preview
# 1    | no preview | failure. display no preview at all
# 2    | plain text | display the plain content of the file
# 3    | fix width  | success. Don't reload when width changes
# 4    | fix height | success. Don't reload when height changes
# 5    | fix both   | success. Don't ever reload
# 6    | image      | success. display the image $cached points to as an image preview

# Meaningful aliases for arguments:
set -o pipefail

path="$1"    # Full path of the selected file
width="$2"   # Width of the preview pane (number of fitting characters)
height="$3"  # Height of the preview pane (number of fitting characters)
cached="$4"  # Path that should be used to cache image previews
EXTDIR="${0%/*}/ext"


# source ~/.shell/profile || exit
# case "$CURR_THEME" in
# light) STYLE=solarized-light ;;
# transparent) STYLE=bright ;;
# dark|*)  STYLE=freya ;; #breeze/freya/clarity
# esac
STYLE=freya

maxln=128

# Find out something about the file:
mimetype=$(file --mime-type -Lb "$path")
extension="${path##*.}"
extension="${extension,,}"

# Functions:
# runs a command and saves its output into $output.  Useful if you need
# the return value AND want to use the output in a pipe
# http://stackoverflow.com/questions/687948/timeout-a-command-in-bash-without-unnecessary-delay
# timed(){(
#     eval "$@" & child=$!
#     trap -- "" SIGTERM
#     (sleep 3 && kill $child 2> /dev/null) &
#     wait $child
# );}

# writes the output of the previously used "try" command
dump() { /bin/echo "$output"; }
# dump() { /bin/echo -E "$output" | head -n "$maxln"; }
# a common post-processing function used after most commands
trim() { head -n "$maxln"; }

try() {
    # (sleep 3 && echo hi && kill $$ >/dev/null 2>&1) & disown
    timeout --kill-after 5 --foreground 3 $@ | head -n "$maxln"
    # kill $! >/dev/null 2>&1

    # output=$(eval '"$@"');
    # output=$(timed "$@");
    # output=$(eval '"$@" & SPID=$!
    #         (sleep 1 && kill "$SPID" >/dev/null) & KPID=$!
    #          wait "$SPID" && kill "$KPID" >/dev/null')
    # output=$(eval '"$@" & SPID=$!
    # ( sleep 5 && kill "$SPID" >/dev/null) &
    # wait "$SPID"')
    # output=$( bash -c '{sleep 5 && kill $$ >/dev/null; }& eval "$@"' )
    # output=$(eval '{sleep 5 && kill $$ >/dev/null; } & "$@"')
    # output=$(timeout --foreground 5 eval '"$@"')
    # output=$(eval 'timeout -k 5 --foreground 3 "$@"')
    # output=$( ( set +b; sleep 3 & "$@" & wait -n; kill -9 $(jobs -p); ) )
}


f_video() {
    # Image preview for videos, disabled by default:
    # ffmpegthumbnailer -i "$path" -o "$cached" -s 0 #&& exit 6
    exiftool "$path" && exit 5 || exit 1
}

case "$extension" in
    # Archive extensions:
    7z|a|ace|alz|arc|arj|bz|bz2|cab|cpio|deb|gz|jar|lha|lz|lzh|lzma|lzo|\
    rpm|rz|t7z|tar|tbz|tbz2|tgz|tlz|txz|tZ|tzo|war|xpi|xz|Z|zip)
        try als "$path" && { dump | trim; exit 0; }
        try acat "$path" && { dump | trim; exit 3; }
        try bsdtar -lf "$path" && { dump | trim; exit 0; }
        exit 1 ;;
    rar) try unrar -p- lt "$path" && { dump | trim; exit 0; } || exit 1 ;;

    doc|xls|ppt) try catdoc "$path" && { dump | trim; exit 0; } || exit 1 ;;

    # PDF documents:
    pdf) try pdftotext -l 10 -nopgbrk -q "$path" - && \
            { dump | trim | fmt -s -w $width; exit 0; } || exit 1;;
    # pdf) try pdftotext -l 10 -nopgbrk -q "$path" - \
    #         | fmt -s ${width:+-w $width} && exit 0 || exit 1 ;;
    # BitTorrent Files
    torrent)
        try transmission-show "$path" && { dump | trim; exit 5; } || exit 1;;
    # HTML Pages:
    htm|html|xhtml)
        # try lynx -dump "$path" && { dump | fmt -s -w $width; exit 4; }
        try elinks -dump "$path" | fmt -s -w $width && exit 4
        try w3m    -dump "$path" | fmt -s -w $width && exit 4
        ;; # fall back to highlight/cat if the text browsers fail
    # otl)
    #     try "$EXTDIR/color-preview" vim 128 "$path" && exit 5 || exit 2
    #     ;;
    flv) f_video ;;
esac


case "$mimetype" in

    text/*|*/xml) # Syntax highlight for text files:
        # if hash pygmentize >/dev/null; then
            # WARNING: you must be sure to have 256 term and downloaded solarized
            # XXX: $height not always valid?
            # try "$EXTDIR/color-preview" pygmentize 128 "$path" && exit 5 || exit 2
            # try pygmentize -g -f terminal256 -O style=solarizeddark,linenos=1 \
            #     <(head -n 50 "$path") && exit 5 || exit 2
            # try "$EXTDIR/pygmentation.py" "$path" && exit 5 || exit 2

        if command -v highlight >/dev/null; then
            # wraps highlight to treat exit code 141 (killed by SIGPIPE) as success
            # NOTE: Chg highlight -> /usr/bin/highlight
            # to workaround conflict with Mint embedded script /usr/local/bin/highlight
            highlight() { command /usr/bin/highlight "$@"; test $? = 0 -o $? = 141; }
            # --wrap-simple --width="$width"
            try highlight --out-format=xterm256 --encoding=utf8 --failsafe \
                --line-numbers --line-number-length=3 --replace-tabs=4 --no-trailing-nl \
                --validate-input --style=$STYLE \
                "$path" && exit 5 || exit 2
        else
            try cat -n "$path" && { dump | trim; exit 5; } || exit 2
        fi ;;

    video/*) { # Image preview for videos, disabled by default:
        # ffmpegthumbnailer -i "$path" -o "$cached" -s 0 #&& exit 6
        exiftool "$path" && exit 5
    } || exit 1 ;;

    image/*) { # Ascii-previews of images:
        # img2txt --gamma=0.6 --width="$width" "$path";
        identify "$path"
    } && exit 4 || exit 1 ;;

    audio/*) { # Display information about media files:
        exiftool "$path" && exit 5
        # Use sed to remove spaces so the output fits into the narrow window
        try mediainfo "$path" | sed 's/  \+:/: /;' && exit 5
    } || exit 1 ;;

esac

{ # Display general information for other files:
    file -Lb "$path" | sed 's/,\s*/\n/g'
    if [ "$(ls -l "$path" | awk '{print $5}')" != "0" ]; then
        maxcol=$(((width-6)/7*2)); actualwidth=$((maxcol/2*7+6))
        printf "<$(printf "=%.0s" {1..62})>\n"
        try xxd -c $maxcol -l $((maxcol*maxln)) "$path" | sed "s/^.\{4\}//; ${maxln}q"
    fi
} && exit 4

exit 1
