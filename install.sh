#!/bin/bash
# To relaunch all: install.sh --reinstall

# On windows under Admin:   Launch Git_Bash.lnk in PrG with Admin rights,
# cd to this script dir and launch by $ exec ./script_name

# ============= Helper to load neccessary functions =============
source ~/.bash/functions 2&> /dev/null
if [ $? -eq 1 ]; then
    source ./cfg/bash/functions
    if [ $? -eq 1 ]; then
        echo "First launch you must do from this script's directory ONLY!"
        [[$-=~i]]&&return||exit 1;
    fi
fi

# Create link for other child scripts to work
if [ ! -f ~/.bash/functions ]; then
    pairLink ~/.bash/functions "$SCRIPT_DIR/cfg/bash/bash/functions"
fi

# ====================== Install type ===========================

# Zero-point (path to this script)
amScriptDir
if [ -z "${SCRIPT_DIR}" ]; then
    echo "Error: no SCRIPT_DIR, 'cause amScriptDir invalid"; [[$-=~i]]&&return||exit; fi
if [ "${SCRIPT_DIR}" == "/" ]; then
    echo "Warning: launch by 'exec ./install.sh'. Attention: it will close your terminal."; squit 1; fi

DEPLOY_DIR="$SCRIPT_DIR/deploy"

if [ ! -e "$HOME/.bash_export" ] || [ "$1" == "--clean" ] || [ "$1" == "-c" ]
then CLEAN_INSTALL=1; shift; else CLEAN_INSTALL=0; fi
# if [ $CLEAN_INSTALL -eq 1 ]
if [ "$1" == "--full" ]
then  FULL_INSTALL=1; shift; else  FULL_INSTALL=0; fi

if  [ "$1" == "--basic" ]
then BASIC_INSTALL=1; CLEAN_INSTALL=0; FULL_INSTALL=0; shift; echo "BASIC"
else BASIC_INSTALL=0;
fi

# ====================== Credentials ============================


# Choose dir for first or next launches
PROFILES_DIR="$HOME/.config/airy_profiles"
if [ ! -d "$PROFILES_DIR" ]; then
    PROFILES_DIR="${SCRIPT_DIR%/*}/erian/airy_profiles"
    if [ ! -d "$PROFILES_DIR" ]
    then PROFILES_DIR="$SCRIPT_DIR"; fi
fi

# Make here path to home-symlink to erian's profile dir
if [ -f "$PROFILES_DIR/profile_auto_choose" ]; then
    CURR_PROF=$("$PROFILES_DIR/profile_auto_choose")
else # Choses ony first from list. Is it OK?
    CURR_PROF="`find "$PROFILES_DIR" -maxdepth 1 -type f -name '*.profile' | head -1`"
    if [ ! -z "$CURR_PROF" ]; then
        CURR_PROF=${CURR_PROF##*/}
        CURR_PROF=${CURR_PROF%.profile}
    else CURR_PROF="guest"; fi
fi


# Intention Validation
echo -n "Proceed \
$([ $BASIC_INSTALL -eq 1 ] && echo 'BASIC ')\
$([ $CLEAN_INSTALL -eq 1 ] && echo 'CLEAN ')\
$([ $FULL_INSTALL -eq 1 ] && echo 'FULL ')\
installation of '${CURR_PROF}' profile? (y/n): "

# if [ -z "${1}" ]; then read answer
# else answer="${1}"; echo "$answer"; fi
if [ "$CURR_PROF" == 'guest' ]; then read answer
else answer="y"; echo "$answer"; fi

case $answer in
    [yY] | [yY][Ee][Ss] ) ;;
    [nN] | [n|N][O|o] ) echo "Rejected"; squit; ;;
    [gG] ) CURR_PROF="guest" ;;
    *) echo "Invalid input"; squit; ;;
esac

# Launch installation
if [ "${CURR_PLTF}" != "MINGW" ] || [ $CLEAN_INSTALL -eq 1 ] ; then
    dst=~/.bash_export
    wbegin
    "$DEPLOY_DIR/profile_export" "$PROFILES_DIR" "$CURR_PROF"
    case "$1" in light|dark|transparent|opaque)
        sed -i "/^export CURR_PROF/a \
export CURR_THEME=$1" "$dst"
        echo ">>>>>>>>>>> Used '$1' theme for all apps"
    ;; esac
fi
source ~/.bash_export
echo "$CURR_PROF :={ $CURR_PLTF, $CURR_HOST, $CURR_USER }"


# ====================== General ================================
echo 'Launching scripts...'

case "${CURR_PLTF}" in
    MINGW) "$DEPLOY_DIR/symlinks.sh" ;;
    Linux) $DEPLOY_DIR/symlinks.sh | sed -e "s@/home/$CURR_USER/@@g" | column -t ;;
esac

#TODO: Move this into pristine.d/vim.pr
if [ ! -d "$HOME/.vim/res/powerline-fonts" ] || [ $CLEAN_INSTALL -eq 1 ]; then
    [ ! $BASIC_INSTALL -eq 1 ] && "$DEPLOY_DIR/vim-setup.sh"
fi

# ======================== Xresources ===========================

if [ "${CURR_PROF}" != "guest" ] && [ "${CURR_PROF}" != "ssh" ] && [ ! $BASIC_INSTALL -eq 1 ] && [ $CLEAN_INSTALL -eq 1 ] ; then
    "$DEPLOY_DIR/generate.sh"
fi
# ======================= Personal ==============================

if [ "${CURR_PROF}" != "guest" ] && [ "${CURR_PROF}" != "ssh" ]; then
    cd "$SCRIPT_DIR"

    [ ! $BASIC_INSTALL -eq 1 ] && git_local_credentials

    "$SCRIPT_DIR/cfg/git/ssh_keys.gen"
    "$SCRIPT_DIR/cfg/git/gitconfig.gen"

    if [ "${CURR_PLTF}" == "Linux" ] && [ $CLEAN_INSTALL -eq 1 ]; then
        "$DEPLOY_DIR/choose_defaults"
        # "$DEPLOY_DIR/shares.sh"
        [ $CLEAN_INSTALL -eq 1 ] && "$DEPLOY_DIR/nosudo_reboot"
    fi
fi

# ====================== Applications ===========================

if [ $FULL_INSTALL -eq 1 ] && [ ! $BASIC_INSTALL -eq 1 ] && [ "${CURR_PLTF}" == "Linux" ]; then
    # Default first
    "$DEPLOY_DIR/pristine"

    # if [ $CLEAN_INSTALL -eq 1 ] ; then
        # if [ "${CURR_HOST}" == "vbox" ]; then
        #     CURR_APP_GROUPS="vbox rofi copyq"
        # elif [ "${CURR_PROF}" == "guest" ]; then
        #     CURR_APP_GROUPS="dev net ranger shell vim zsh"
        # else
        #     CURR_APP_GROUPS="dev_opengl rofi copyq grub tlp wuala evernote palemoon"
        # fi
        # $DEPLOY_DIR/pristine $CURR_APP_GROUPS
    # fi
fi

# ===============================================================

amPause
