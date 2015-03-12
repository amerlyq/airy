# bindkey '^Y' yank-last-arg # No such func
zle -N yank-current yank_current
bindkey "^Y" yank-current
bindkey -a "^Y" yank-current
function yank_current() {
    # If empty cmd line, copy last line from history
    xsel --input --clipboard <<< "${BUFFER:-$(fc -ln -1)}"
}

zle -N prepend-sudo prepend_sudo
bindkey "^S" prepend-sudo
function prepend_sudo() {
    if ! [ "$BUFFER" ]; then
        BUFFER="$(fc -ln -1)"
    fi
    if [ "$BUFFER" != "${BUFFER#'sudo '}" ]; then
        BUFFER="${BUFFER#'sudo '}"
    else
        BUFFER="sudo $BUFFER"
        CURSOR=$(($CURSOR+5))
    fi
}

zle -N synchro-dir-push synchro_dir_push
function synchro_dir_push {
    curr="$(pwd)"
    if [ "$curr" != ~ ]; then
        printf "$curr\n" > /tmp/zsh_chosedir
    fi
}
zle -N synchro-dir-pop synchro_dir_pop
function synchro_dir_pop {
if [ -f /tmp/zsh_chosedir ]; then
    curr="$(cat /tmp/zsh_chosedir)"
    if [ "$(pwd)" != "$curr" ]; then
        # Change directories and redisplay the prompt
        # (Still don't fully understand this magic combination of commands)
        # [[ -o zle ]] && zle -R && cd "$(cat ~/.pwd)" && precmd && zle reset-prompt 2>/dev/null
        cd "$curr" && zle reset-prompt
    fi
fi
}

bindkey -a "^O" synchro-dir-pop
bindkey "^O" synchro-dir-push

### ----------- Untested
# autoload smart-insert-last-word
# bindkey "\e." smart-insert-last-word-wrapper
# bindkey "\e," smart-insert-prev-word
# zle -N smart-insert-last-word-wrapper
# zle -N smart-insert-prev-word
# function smart-insert-last-word-wrapper() {
#     _altdot_reset=1
#     smart-insert-last-word
# }
# function smart-insert-prev-word() {
#     if (( _altdot_reset )); then
#         _altdot_histno=$HISTNO
#         (( _altdot_line=-_ilw_count ))
#         _altdot_reset=0
#         _altdot_word=-2
#     elif (( _altdot_histno != HISTNO || _ilw_cursor != $CURSOR )); then
#         _altdot_histno=$HISTNO
#         _altdot_word=-1
#         _altdot_line=-1
#     else
#         _altdot_word=$((_altdot_word-1))
#     fi
#         smart-insert-last-word $_altdot_line $_altdot_word 1
#     if [[ $? -gt 0 ]]; then
#         _altdot_word=-1
#         _altdot_line=$((_altdot_line-1))
#         smart-insert-last-word $_altdot_line $_altdot_word 1
#     fi
# }
### -----------

