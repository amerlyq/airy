
# Disable suspending on <C-s>, <C-q>
setopt noflowcontrol
stty stop '' -ixoff -ixon

# new history lines are added to the $HISTFILE incrementally (as soon as they are entered), rather than waiting until the shell exits.
setopt INC_APPEND_HISTORY

## don't beep on errors
setopt nobeep
## type the name of a directory -> it will become the current directory
setopt autocd
## glob's expanding magic
setopt extended_glob
## make aliases available in scripts
# setopt aliases


