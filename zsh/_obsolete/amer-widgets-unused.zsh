zle -N amer-prepend-sudo _prepend_sudo
function _prepend_sudo() {
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

## Autocmd
# ELSE
# function zle-line-init zle-keymap-select {
#     VIM_PROMPT="%{$fg_bold[yellow]%} [% NORMAL]%  %{$reset_color%}"
#     RPS1="${${KEYMAP/vicmd/$VIM_PROMPT}/(main|viins)/}$(git_custom_status) $EPS1"
#     zle reset-prompt
# }
## Prompt always in command-mode
# function zle-line-init {
#     vi-cmd-mode
# }
# zle -N zle-line-init
## zle -N zle-keymap-select

