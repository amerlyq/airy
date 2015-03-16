# SEE
#   print -s : http://linux.die.net/man/1/zshbuiltins

zle -N amer-yank-current _yank_current
function _yank_current() {
    # If empty cmd line, copy last line from history
    xsel --input --clipboard <<< "${BUFFER:-$(fc -ln -1)}"
}

# Send current buffer to history and replace it from '+' register
zle -N amer-past-current _past_current
function _past_current() {
    if [ -n "$BUFFER" ]; then print -s "$BUFFER"; fi
    BUFFER="$(xsel --output --clipboard)"
}

## Re-run and add lines from output to completion menu
# We can't simply '|tee' output of each command, as we has 'vim' and 'less'
# NOTE: Now, while editing cmdline, ^O will copy output of previous command,
#   which you can paste in cmdline. Or you can check if buffer empty and on
#   nonempty buffer execute current command and copy its output.
zle -N amer-yank-output _yank_output
function _yank_output() {
    eval $(fc -l -n -1) | xsel --input --clipboard
}

## Re-run and add lines from output to completion menu
zle -C jh-prev-comp menu-complete _jh-prev-result
function _jh-prev-result() {
    cmd_output_buf=$(eval `fc -l -n -1`)
    set -A hlist ${(@s/
/)cmd_output_buf}
    compadd - ${hlist}
}

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


# bindkey -a "^O" synchro-dir-pop
# bindkey "^O" synchro-dir-push
zle -N synchro-dir-push synchro_dir_push
zle -N synchro-dir-pop synchro_dir_pop
function synchro_dir_push {
    curr="$(pwd)"
    if [ "$curr" != ~ ]; then
        printf "$curr\n" > /tmp/aura/zsh_chosedir
    fi
}
function synchro_dir_pop {
if [ -f /tmp/aura/zsh_chosedir ]; then
    curr="$(cat /tmp/aura/zsh_chosedir)"
    if [ "$(pwd)" != "$curr" ]; then
        # Change directories and redisplay the prompt
        # (Still don't fully understand this magic combination of commands)
        # [[ -o zle ]] && zle -R && cd "$(cat ~/.pwd)" && precmd && zle reset-prompt 2>/dev/null
        cd "$curr" && zle reset-prompt
    fi
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

