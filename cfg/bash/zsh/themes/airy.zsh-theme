# vim:ft=zsh ts=2 sw=2 sts=2
# I need git ahead/behind markers
# http://sebastiancelis.com/2009/11/16/zsh-prompt-git-users/
# make different colors for 16 and 256 term

functions rbenv_prompt_info >& /dev/null || rbenv_prompt_info(){}

function theme_precmd {
    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 1 ))

    ###
    # Truncate the path if it's too long.

    PR_FILLBAR=""
    PR_PWDLEN=""

    local pwdsize=${#${(%):-%~}}
    local promptsize=${(%):---(%n@%m:%l)`git_prompt_info`--()-}
    promptsize=${#promptsize}
    local rubyprompt=`rvm_prompt_info || rbenv_prompt_info`
    local rubypromptsize=${#${rubyprompt}}

    if [[ "$promptsize + $rubypromptsize + $pwdsize" -gt $TERMWIDTH ]]; then
      ((PR_PWDLEN=$TERMWIDTH - $promptsize))
    else
      PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $rubypromptsize + $pwdsize)))..${PR_HBAR}.)}"
    fi

}


setopt extended_glob
theme_preexec () {
    if [[ "$TERM" == "screen" ]]; then
    local CMD=${1[(wr)^(*=*|sudo|-*)]}
    echo -n "\ek$CMD\e\\"
    fi
}


setprompt () {
    ###
    # Need this so the prompt will work.

    setopt prompt_subst


    ###
    # See if we can use colors.

    autoload colors zsh/terminfo
    if [[ "$terminfo[colors]" -ge 8 ]]; then
    colors
    fi
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
    eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
    eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
    (( count = $count + 1 ))
    done
    PR_NO_COLOUR="%{$terminfo[sgr0]%}"

# BOLD="%{$(tput bold)%}"
# RESET="%{$(tput sgr0)%}"
# SOLAR_YELLOW="%{$(tput setaf 136)%}"
# SOLAR_ORANGE="%{$(tput setaf 166)%}"
# SOLAR_RED="%{$(tput setaf 124)%}"
# SOLAR_MAGENTA="%{$(tput setaf 125)%}"
# SOLAR_VIOLET="%{$(tput setaf 61)%}"
# SOLAR_BLUE="%{$(tput setaf 33)%}"
# SOLAR_CYAN="%{$(tput setaf 37)%}"
# SOLAR_GREEN="%{$(tput setaf 64)%}"
# SOLAR_WHITE="%{$(tput setaf 254)%}"

    ###
    # Modify Git prompt
    ZSH_THEME_GIT_PROMPT_PREFIX="("
    ZSH_THEME_GIT_PROMPT_SUFFIX=")"
    ZSH_THEME_GIT_PROMPT_DIRTY=""
    ZSH_THEME_GIT_PROMPT_CLEAN=""

    #✓○✚➜
    ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[green]%}◯"
    ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}ϟ"
    ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}✗"
    ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[cyan]%}➤"
    ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[magenta]%}ø"
    ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[white]%}♯"
    ZSH_THEME_GIT_PROMPT_STASHED="%{$fg[white]%}✴"
    ZSH_THEME_GIT_PROMPT_AHEAD="%{$fg[white]%}▲"
    ZSH_THEME_GIT_PROMPT_BEHIND="%{$fg[white]%}▼"
    ZSH_THEME_GIT_PROMPT_DIVERGED="%{$fg[white]%}☯"

    ###
    # See if we can use extended characters to look nicer.
    # UTF-8 Fixed

    if [[ $(locale charmap) == "UTF-8" ]]; then
        PR_SET_CHARSET=""
        PR_SHIFT_IN=""
        PR_SHIFT_OUT=""
        PR_HBAR="─"
        PR_LEND="╾"
        PR_REND="╼"
        PR_ULCORNER="┌"
        PR_LLCORNER="└"
        PR_LRCORNER="┘"
        PR_URCORNER="┐"
    else
        typeset -A altchar
        set -A altchar ${(s..)terminfo[acsc]}
        # Some stuff to help us draw nice lines
        PR_SET_CHARSET="%{$terminfo[enacs]%}"
        PR_SHIFT_IN="%{$terminfo[smacs]%}"
        PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
        PR_HBAR='$PR_SHIFT_IN${altchar[q]:--}$PR_SHIFT_OUT'
        PR_ULCORNER='$PR_SHIFT_IN${altchar[l]:--}$PR_SHIFT_OUT'
        PR_LLCORNER='$PR_SHIFT_IN${altchar[m]:--}$PR_SHIFT_OUT'
        PR_LRCORNER='$PR_SHIFT_IN${altchar[j]:--}$PR_SHIFT_OUT'
        PR_URCORNER='$PR_SHIFT_IN${altchar[k]:--}$PR_SHIFT_OUT'
     fi


    ###
    # Decide if we need to set titlebar text.

    case $TERM in
    xterm*)
        PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
        ;;
    screen)
        PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
        ;;
    *)
        PR_TITLEBAR=''
        ;;
    esac


    ###
    # Decide whether to set a screen title
    if [[ "$TERM" == "screen" ]]; then
    PR_STITLE=$'%{\ekzsh\e\\%}'
    else
    PR_STITLE=''
    fi


    ###
    # Finally, the prompt.
    AM_LN=$PR_RED #"%{$(tput setaf 124)%}"
    AM_PWD="%{$(tput setaf 220)%}" #$PR_YELLOW
    AM_GIT="%{$(tput setaf 92)%}"

    # $AM_LN$PR_HBAR${(e)PR_FILLBAR}$PR_REND\
    PROMPT='$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}\
$AM_LN$PR_ULCORNER$PR_HBAR$PR_HBAR\
${PR_GREY}[$AM_PWD%$PR_PWDLEN<...<%~%<<$PR_GREY]\
$AM_GIT`git_prompt_info`\

$AM_LN$PR_LLCORNER\
$PR_NO_COLOUR`git_prompt_status`\
$AM_LN$PR_REND$PR_NO_COLOUR '

# `rvm_prompt_info || rbenv_prompt_info`\

    # display exitcode on the right when >0
    return_code="%(?..%{$fg[red]%}%? ↵ %{$reset_color%})"
    RPROMPT='  $return_code$AM_LN$PR_HBAR\
$PR_GREY($PR_CYAN%(!.%SROOT%s.%n)$PR_GREY@$PR_GREEN%m:%l$PR_GREY)\
$PR_GREY($PR_YELLOW%D{%H:%M:%S}$PR_GREY)$PR_NO_COLOUR'

# history number | $PR_CYAN$PR_HBAR%!

    PS2='$PR_CYAN$PR_HBAR\
$PR_BLUE$PR_HBAR(\
$PR_LIGHT_GREEN%_$PR_BLUE)$PR_HBAR\
$PR_CYAN$PR_HBAR$PR_NO_COLOUR '
}

setprompt

autoload -U add-zsh-hook
add-zsh-hook precmd  theme_precmd
add-zsh-hook preexec theme_preexec
