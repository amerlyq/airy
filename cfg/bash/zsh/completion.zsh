# COMPLETION SETTINGS
# add custom completion scripts
fpath=(~/.bash/zsh/completion.d $fpath)

# compsys initialization
# autoload -U compinit
# compinit

# show completion menu when number of options is at least 2
# zstyle ':completion:*' menu select=2

## To see it you may need to add the following line into your .zshrc:
zstyle ":completion:*:descriptions" format "%B%d%b"
