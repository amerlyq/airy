# Man
#   http://zsh.sourceforge.net/Guide/zshguide04.html
#   http://zsh.sourceforge.net/Doc/Release/Zsh-Line-Editor.html#Zle-Builtins
# Available widgets as cheetsheet
#   http://www.bash2zsh.com/zsh_refcard/refcard.pdf

# List of widgets and structure of commands
#   http://unix.stackexchange.com/questions/122078/how-to-bind-a-key-sequence-to-a-widget-in-vi-cmd-mode-zsh

# Vim text-objects, tex-between
#   https://github.com/hchbaw/opp.zsh



# NOTE: setting KEYTIMEOUT small seems to break the key-binding #bindkey jj
export KEYTIMEOUT=20
bindkey -v

## Navigation
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^F' forward-char
bindkey '^B' backward-char
bindkey '^T' forward-word
bindkey '^Q' backward-word


## Editing
bindkey '^_' undo
bindkey '^Z' undo
bindkey '^D' delete-char
bindkey '^H' backward-delete-char
bindkey '^?' backward-delete-char
bindkey '^G' kill-word
bindkey '^W' backward-kill-word
bindkey '^K' kill-line
bindkey '^U' backward-kill-line


## Emacs duplicates
bindkey '\eOH'  beginning-of-line # Home
bindkey '\eOF'  end-of-line       # End
bindkey '\e[2~' overwrite-mode    # Insert
bindkey '\M-f'  forward-word      # Alt-f
bindkey '\M-b'  backward-word     # Alt-b
bindkey '\M-d'  kill-word         # Alt-d


# History completion on pgup and pgdown
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end  history-search-end

## History
bindkey    '^R' history-incremental-search-backward
bindkey -a '^R' history-incremental-pattern-search-backward
bindkey    '^S' history-incremental-search-forward
bindkey -a '^S' history-incremental-pattern-search-forward
# Prev-hist-cmd, depending on text from beginning till cursor #'\e[A','\e[B'
bindkey    '^P' up-line-or-history                 #up-line-or-search
bindkey    '^N' down-line-or-history               #down-line-or-search
# bindkey -a '^P' history-substring-search-up        #up-history
# bindkey -a '^N' history-substring-search-down      #down-history
bindkey -a '^P' history-beginning-search-backward
bindkey -a '^N' history-beginning-search-forward


## Command-line copy-paste-edit
bindkey    '\C-y' amer-yank-current
bindkey -a '\C-y' amer-yank-current
bindkey    '\C-^' amer-past-current
bindkey -a '\C-^' amer-past-current
bindkey    '\C-o' amer-yank-output
bindkey -a '\C-o' amer-yank-output

bindkey '\C-x\C-m' set-fast-exec-cmd  # Save last cmdline to rerun by ',m'
bindkey '\C-x\C-j' jh-prev-comp       # Run with last output autocomplete
bindkey -a  '\C-u' jh-prev-comp       # Run with last output autocomplete
bindkey '\C-x\C-e' edit-command-line
bindkey -a  '\C-t' edit-command-line

bindkey '\C-x\C-s' synchro-dir-push
bindkey '\C-x\C-l' synchro-dir-pop




## Integration
# ranger -- fast in/out with keeping expression  #bindkey -s -M vicmd
# bindkey    ',s' amer-toggle-ranger
# bindkey -s ',s' amer-toggle-ranger
# bindkey -s  's' amer-toggle-ranger

# <Enter>
bindkey  -s ',j' '\n'
# quit
bindkey  -s ',d' '^Uq\n'
bindkey -as  'q' 'Sq\n'
bindkey -as ',d' 'Sq\n'
# ranger
bindkey  -s ',s' '^Us\n'
bindkey -as  's' 'Ss\n'
# make
bindkey  -s ',m' '^Uabyss\n'
bindkey -as ',m' 'Sabyss\n'

# TODO: bindkey -s '<keystroke>' '^qfoo\n'
#   where ^q is bound to 'push-line'.
# It saves current cmdline, and restores it back after running foo


### Miscellaneous
bindkey ' ' magic-space  # [Space] - do history expansion
## On <F12> in vim mode loads config debug aliases
bindkey -as '^[[24~' '0d$isource ~/.shell/func.d/debug\n\e'
## Handle SIGINT when completing
# bindkey '^I' interruptible-expand-or-complete
## Autocomplete paths only on <S-Tab> (SEE: amer-widgets)
bindkey '\e[Z' complete  # SEE ALT inside widgets.
## Insert literal \n for multiline editing in emacs-mode (for vi use o/O)
# self-insert-unmeta

## Ignore focus events ::: https://github.com/amerlyq/vim-focus-events
#FIXME: -- I don't know how to make it working in zsh, as in inputrc
# bindkey '\e[O' ''
# bindkey '\e[I' ''

## Menu completion
# For '-M menuselect' (http://www.zsh.org/mla/users/2009/msg01018.html
zmodload zsh/complist
# bindkey -M menuselect '^M' undefined-key
bindkey -M menuselect '^M' .accept-line
# bindkey -M menuselect '|' .magic-space


## No such widgets:
#bindkey '^[e' expand-cmd-path
# "\C-p": menu-complete
#bindkey '^[^I' reverse-menu-complete
#bindkey '^X^N' accept-and-infer-next-history
#bindkey '^Y' yank-last-arg # No such func
# bindkey '^\' character-search               # <C-4>, <C-\>
# bindkey '^]' character-search-backward      # <C-5>, <C-]>
