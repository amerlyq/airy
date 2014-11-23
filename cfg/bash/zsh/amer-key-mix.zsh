# List of widgets and structure of commands
#   http://www.math.technion.ac.il/Site/computing/docs/zsh/zsh_17.html
#   http://unix.stackexchange.com/questions/122078/how-to-bind-a-key-sequence-to-a-widget-in-vi-cmd-mode-zsh
# Vim text-objects, tex-between
#   https://github.com/hchbaw/opp.zsh

# vi-mode
bindkey -v

bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^B' backward-char
bindkey '^F' forward-char
bindkey '^Z' backward-word
bindkey '^X' forward-word

bindkey '^D' delete-char
bindkey '^H' backward-delete-char
bindkey '^?' backward-delete-char
bindkey '^W' backward-kill-word
bindkey '^T' kill-word
bindkey '^K' kill-line
bindkey '^U' backward-kill-line

bindkey '^P' history-substring-search-up    #up-history
bindkey '^N' history-substring-search-down  #down-history
bindkey '^R' history-incremental-pattern-search-backward #history-incremental-search-backward
# Prev command from history, depending on text till cursor #'\e[A','\e[B'
bindkey '^P' up-line-or-search      #history-beginning-search-backward
bindkey '^N' down-line-or-search    #history-beginning-search-forward

# bindkey '^O' ...
bindkey '^\' character-search               # <C-4>, <C-\>
bindkey '^]' character-search-backward      # <C-5>, <C-]>
bindkey '^_' undo

bindkey ' ' magic-space # [Space] - do history expansion
bindkey '\C-x\C-e' edit-command-line

bindkey -a '^R' history-incremental-search-backward
bindkey -a '^S' history-incremental-search-forward

#bindkey '^[e' expand-cmd-path
# "\C-p": menu-complete
#bindkey '^[^I' reverse-menu-complete
#bindkey '^X^N' accept-and-infer-next-history

# RANGER - fast in/out with keeping expression
bindkey -s -M vicmd  's' '0d$is\n^[p'
bindkey -s -M vicmd  'q' '0d$iq\n'
bindkey -s -M vicmd ',d' '0d$iq\n'

# NOTE: setting KEYTIMEOUT small seems to break the key-binding #bindkey jj
# bindkey -M viins 'jj' vi-cmd-mode
export KEYTIMEOUT=20
bindkey -s ',d' '^Uq\n'
bindkey -s ',s' '^Us\n'
bindkey -s 'lf' '^['
bindkey -s 'kd' '^M'

alias sh-rc-reload="source ~/.zshrc && echo 'ZSH config reloaded'"
bindkey -s -M vicmd '^[[24~' '0d$ish-rc-reload\n\e'


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

