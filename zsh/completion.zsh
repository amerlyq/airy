# COMPLETION SETTINGS
# add custom completion scripts
# NOTE: already extended before prezto
# fpath=(${ZDOTDIR}/cfg/completion.d $fpath)

# EXPL: speed up completion
zstyle ':completion::complete:*' accept-exact '*(N)'

# Disable inserting literal TAB on empty prompt
# zstyle ':completion:*' insert-tab false

# Fallback to file completion
# https://www.zsh.org/mla/users/2011/msg00974.html
zstyle ':completion:*' completer _expand _complete _files _correct _approximate

# compsys initialization
# autoload -U compinit
# compinit

# Don't expand aliases _before_ completion has finished. Like: git comm-[tab]
# WARNING: breaks auto-completion for 'gco', etc -- need to setup all manually
# setopt complete_aliases

# show completion menu when number of options is at least 2
# zstyle ':completion:*' menu select=2

## To see it you may need to add the following line into your .zshrc:
# zstyle ":completion:*:descriptions" format "%B%d%b"

# SEE /usr/share/zsh/functions/Completion/Unix/_git
compdef r.git-all=git
# for c in st pl ph; do eval "function _git-$c { _git; }"; done

# IDEA: place 'compdef' near aliases/functions inside alias.d
#   -- and in bash create empty stub compdef(){} to resolve unknown function
#   BUT I need to keep separate completion file for binaries anyway
compdef r.ssh=ssh

# SEE Partial completion for git subcommands (like my $ compdef grI=git-rebase)
#   http://unix.stackexchange.com/questions/128199/how-do-i-set-zsh-autocompletion-rules-for-second-argument-of-function-to-an-ex

# ALT?
# autoload -Uz compinit && compinit
# compdef _git r.git-all   # Use X completion for Y command
# compdef '_dispatch git git' Gg          # Seems like must work for aliases
