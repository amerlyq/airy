# COMPLETION SETTINGS
# add custom completion scripts
fpath=(~/.shell/zsh/completion.d $fpath)

# compsys initialization
# autoload -U compinit
# compinit

# show completion menu when number of options is at least 2
# zstyle ':completion:*' menu select=2

## To see it you may need to add the following line into your .zshrc:
# zstyle ":completion:*:descriptions" format "%B%d%b"

# SEE /usr/share/zsh/functions/Completion/Unix/_git
compdef prg.d/git-recursive=git
for c in st pl ph; do eval "function _git-$c { _git; }"; done

compdef r.ssh=ssh

# SEE Partial completion for git subcommands (like my $ compdef grI=git-rebase)
#   http://unix.stackexchange.com/questions/128199/how-do-i-set-zsh-autocompletion-rules-for-second-argument-of-function-to-an-ex

# ALT?
# autoload -Uz compinit && compinit
# compdef _git ~/.bin/prg.d/git-recursive   # Use X completion for Y command
# compdef '_dispatch git git' Gg          # Seems like must work for aliases
