#!/bin/bash
# Gen: ssh-keys, .gitconfig
# Arg: all-new -- for re-generating rsa-pairs

source ~/.bash/functions
amScriptDir -s
if [ -z "$SCRIPT_DIR" ]; then echo "Error: SCRIPT_DIR"; exit 1; fi

# =================== Multi--SSH ============================
ARGS="$1"
genssh(){ # $1 -- @mail, $2 -- path/to/key
    local mail="$1" idn="$HOME/.ssh/$2"
    if [ ! -f "$idn" ] || [ "$ARGS" == "--reinstall" ]; then
        ssh-keygen -t rsa -C "$mail" -N "" -f "$idn"
        echo "!!! Copy generated *.pub key to your servers"
    fi
}

genssh "$WORK_MAIL" id_rsa
genssh "$MAIN_MAIL" git_rsa
genssh "$MAIN_MAIL" lok_rsa

if [ "$CURR_PROF" == "work" ]; then
    genssh "$WORK_MAIL" srk_rsa
fi

# ==================== ~/.gitconfig =========================

dst="$HOME/.gitconfig"
wbegin
    git config --global user.name  "$WORK_NAME"
    git config --global user.email "$WORK_MAIL"
wcat "$SCRIPT_DIR/gitconfig_base"
echo "W: ~/.gitconfig"

pairLink ~/.gitignore "$SCRIPT_DIR/gitignore"

# ===========================================================

# ssh-add "$stdkey"
# ssh-add "$mykey"
# ssh-add -l # check your saved keys
# ssh-add -D # delete all cached keys

## Copy .pub keys to site
# cat "$stdkey.pub"
# clip < "$stdkey.pub"

amPause
