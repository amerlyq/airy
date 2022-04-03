#!/usr/bin/env bash
#
#%SRC: https://old.reddit.com/r/qutebrowser/comments/p490cf/evaluate_javascript_in_qutebrowser/
#%USAGE: $ ./$0
set -r -o errexit -o errtrace -o noclobber -o noglob -o nounset -o pipefail

## Env Setup
ROOT="$HOME/bank-autoscrape/chase"
JS_SCRIPT="$ROOT/src/action.js"
ACCOUNT=$(gpg --decrypt "$ROOT/data/account.gpg" |& tail -n 1)
PASSWORD=$(gpg --decrypt "$ROOT/data/password.gpg" |& tail -n 1)

## Open chase in qutebrowser.
echo "open -t https://secure05b.chase.com/web/auth/dashboard" >> "$QUTE_FIFO"
sleep 10

## Use xdotool to auto login.
## Web automation tool like Selenium gets detected easily by banks.
xdotool key i # qutebrowser insert mode
xdotool type "$ACCOUNT"
xdotool key Tab
xdotool type "$PASSWORD"
sleep 1
xdotool key Return
sleep 10

echo "jseval -f $JS_SCRIPT" >> "$QUTE_FIFO"

## Finally, press enter to confirm the download.
for i in {40..1}; do
    notify-send -t 1000 "Final action in $i seconds..";
    sleep 1;
done
xdotool key Return

exit
