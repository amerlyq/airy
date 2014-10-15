# List of widgets and structure of commands
#   http://www.math.technion.ac.il/Site/computing/docs/zsh/zsh_17.html
#   http://unix.stackexchange.com/questions/122078/how-to-bind-a-key-sequence-to-a-widget-in-vi-cmd-mode-zsh
# Vim text-objects, tex-between
#   https://github.com/hchbaw/opp.zsh

# vi-mode
bindkey -v
# bindkey -M viins 'jj' vi-cmd-mode

bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^B' backward-char
bindkey '^F' forward-char
bindkey '^X' backward-word
bindkey '^T' forward-word

bindkey '^D' delete-char
bindkey '^H' backward-delete-char
bindkey '^?' backward-delete-char
bindkey '^W' backward-kill-word
bindkey '^O' kill-word
bindkey '^K' kill-line
bindkey '^Z' backward-kill-line

bindkey '^P' history-substring-search-up    #up-history
bindkey '^N' history-substring-search-down  #down-history
bindkey '^R' history-incremental-pattern-search-backward #history-incremental-search-backward
# Prev command from history, depending on text till cursor #'\e[A','\e[B'
bindkey '^P' up-line-or-search      #history-beginning-search-backward
bindkey '^N' down-line-or-search    #history-beginning-search-forward

bindkey '^\' character-search               # <C-4>, <C-\>
bindkey '^]' character-search-backward      # <C-5>, <C-]>
bindkey '^_' undo

bindkey -a '^R' history-incremental-search-backward
bindkey ' ' magic-space # [Space] - do history expansion
bindkey '\C-x\C-e' edit-command-line

#bindkey '^[e' expand-cmd-path
# "\C-p": menu-complete
#bindkey '^[^I' reverse-menu-complete
#bindkey '^X^N' accept-and-infer-next-history

# RANGER - fast in/out with keeping expression
bindkey -s -M vicmd 's' '0d$is\np'

# bindkey '^Y' yank-last-arg # No such func
zle -N yank-current yank_current
bindkey "^Y" yank-current
function yank_current() {
    if ! [ "$BUFFER" ]; then
        BUFFER="$(fc -ln -1)"
    fi
    printf "$BUFFER" | xsel --input --clipboard
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


# # VI MODE KEYBINDINGS (ins mode)
# bindkey -M viins '^a'    beginning-of-line
# bindkey -M viins '^e'    end-of-line
# bindkey -M viins '^k'    kill-line
# bindkey -M viins '^r'    history-incremental-pattern-search-backward
# bindkey -M viins '^s'    history-incremental-pattern-search-forward
# bindkey -M viins '^p'    up-line-or-history
# bindkey -M viins '^n'    down-line-or-history
# bindkey -M viins '^y'    yank
# bindkey -M viins '^w'    backward-kill-word
# bindkey -M viins '^u'    backward-kill-line
# bindkey -M viins '^h'    backward-delete-char
# bindkey -M viins '^?'    backward-delete-char
# bindkey -M viins '^_'    undo
# bindkey -M viins '^x^r'  redisplay
# bindkey -M viins '\eOH'  beginning-of-line # Home
# bindkey -M viins '\eOF'  end-of-line       # End
# bindkey -M viins '\e[2~' overwrite-mode    # Insert
# bindkey -M viins '\ef'   forward-word      # Alt-f
# bindkey -M viins '\eb'   backward-word     # Alt-b
# bindkey -M viins '\ed'   kill-word         # Alt-d

# # VI MODE KEYBINDINGS (cmd mode)
# bindkey -M vicmd '^a'    beginning-of-line
# bindkey -M vicmd '^e'    end-of-line
# bindkey -M vicmd '^k'    kill-line
# bindkey -M vicmd '^r'    history-incremental-pattern-search-backward
# bindkey -M vicmd '^s'    history-incremental-pattern-search-forward
# bindkey -M vicmd '^p'    up-line-or-history
# bindkey -M vicmd '^n'    down-line-or-history
# bindkey -M vicmd '^y'    yank
# bindkey -M vicmd '^w'    backward-kill-word
# bindkey -M vicmd '^u'    backward-kill-line
# bindkey -M vicmd '/'     vi-history-search-forward
# bindkey -M vicmd '?'     vi-history-search-backward
# bindkey -M vicmd '^_'    undo
# bindkey -M vicmd '\ef'   forward-word                      # Alt-f
# bindkey -M vicmd '\eb'   backward-word                     # Alt-b
# bindkey -M vicmd '\ed'   kill-word                         # Alt-d
# bindkey -M vicmd '\e[5~' history-beginning-search-backward # PageUp
# bindkey -M vicmd '\e[6~' history-beginning-search-forward  # PageDown


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

export KEYTIMEOUT=1
