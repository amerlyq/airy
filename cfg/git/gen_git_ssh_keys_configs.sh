#!/bin/bash
# Gen: ssh-keys, .ssh/config, .gitconfig
# Arg: all-new -- for re-generating rsa-pairs

amScriptDir -s
if [ -z "$SCRIPT_DIR" ]; then echo "Error: SCRIPT_DIR"; exit 1; fi

# =================== Multi--SSH ============================
ARGS="$1"
genssh(){ # $1 -- @mail, $2 -- path/to/key
    if [ ! -f "$2" ] || [ "$ARGS" == "--reinstall" ]; then
        ssh-keygen -t rsa -C "$1" -N "" -f "$2"
        echo "!!! Copy generated *.pub key to your servers"
    fi
}
stdkey="$HOME/.ssh/id_rsa"
gitkey="$HOME/.ssh/git_rsa"
srkkey="$HOME/.ssh/srk_rsa"

genssh "$WORK_MAIL" "$stdkey"
genssh "$MAIN_MAIL" "$gitkey"
genssh "$WORK_MAIL" "$srkkey"

# ==================== ~/.gitconfig =========================

dst="$HOME/.gitconfig"
wbegin
    git config --global user.name  "$WORK_NAME"
    git config --global user.email "$WORK_MAIL"
wcat "$SCRIPT_DIR/gitconfig_base"
echo "W: ~/.gitconfig"

# ==================== ~/.ssh/config ========================

wacc() {
    wstr "Host $1
    HostName $2
    User $3
    IdentityFile $4
"
}

# Instead of this config, you can add param for each 'git push'
#$ git ... -key ~/.ssh/git_rsa (or only for remote add?)
dst="$HOME/.ssh/config"
wbegin
wstr "### Multi--SSH config ###
"
wstr "# Accounts"
wacc ghub github.com git "$gitkey"
wacc glab gitlab.com git "$gitkey"
wacc srkb $SRK_SERVER "${WORK_MAIL%@*}" "$srkkey"
wacc amazon $AMAZON_SERVER ubuntu "$HOME/.ssh/seclab-cloud.pem"

echo "W: ~/.ssh/config"

pairLink ~/.gitignore "$SCRIPT_DIR/gitignore"

echo "
!   You will need to replace your name and email in each your own   !
!   local git repository, to elude overlapping with work activity   !
"

# To make use of this, change 'remote url' of git repository
#$ git remote add origin git@github.com:user/repo.git   # Initial
#$ git remote set-url origin ghub:user/repo.git         # Existing

# ===========================================================

# ssh-add "$stdkey"
# ssh-add "$mykey"
# ssh-add -l # check your saved keys
# ssh-add -D # delete all cached keys

## Copy .pub keys to site
# cat "$stdkey.pub"
# clip < "$stdkey.pub"

amPause
