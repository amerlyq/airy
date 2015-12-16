# SEE
#   print -s : http://linux.die.net/man/1/zshbuiltins
# Show list of all widgets $ zle -la, or M-x in emacs, or ':' in vi
#   http://sgeb.io/articles/zsh-zle-closer-look-custom-widgets/

# If empty cmd line, copy last line from history
zle -N amer-yank-current _yank_current
function _yank_current() { xsel -ib <<< "${BUFFER:-$(fc -ln -1)}"; }

# NOTE: \C-o -- always re-run previous command and copy its output -- so you able to insert it inside new currently created command. (But it could check if BUFFER not empty and execute/insert current command)
# We can't simply '|tee' output of each command, as we has 'vim' and 'less'
zle -N amer-yank-output _yank_output
function _yank_output() { eval $(fc -l -n -1) 2>&1 | xsel -ib; }

# Send current buffer to history and replace it from '+' register
zle -N amer-past-current _past_current
function _past_current() { print -s "$BUFFER"; BUFFER="$(xsel -ob)"; }

zle -N amer-toggle-ranger _toggle_ranger
function _toggle_ranger() { print -s "$BUFFER"; eval "ranger"; }

## Re-run and add lines from output to completion menu
zle -C jh-prev-comp menu-complete _jh-prev-result
function _jh-prev-result() {
    cmd_output_buf=$(eval `fc -l -n -1`)
    set -A hlist ${(@s/
/)cmd_output_buf}
    compadd - ${hlist}
}

zle -C amer-coplete-bin menu-complete _amer-coplete-bin
function _amer-coplete-bin() {
    cmd_output_buf=$(cd ~/.bin && ls **/*(.x))
    set -A hlist ${(@s/
/)cmd_output_buf}
    compadd - ${hlist}
}


zle -N synchro-dir-push synchro_dir_push
zle -N synchro-dir-pop synchro_dir_pop
function synchro_dir_push {
    curr="$(pwd)"
    if [[ "$curr" != ~ ]]; then
        printf "$curr\n" >! ${TMPDIR:-/tmp}/zsh_chosendir
    fi
}
function synchro_dir_pop {
if [[ -f ${TMPDIR:-/tmp}/zsh_chosendir ]]; then
    curr="$(cat ${TMPDIR:-/tmp}/zsh_chosedir)"
    if [ "$(pwd)" != "$curr" ]; then
        # Change directories and redisplay the prompt
        # (Still don't fully understand this magic combination of commands)
        # [[ -o zle ]] && zle -R && cd "$(cat ~/.pwd)" && precmd && zle reset-prompt 2>/dev/null
        cd "$curr" && zle reset-prompt
    fi
fi
}

# Autocomplete paths only, ignore possible options
zle -C complete complete-word complete-files
function complete-files() { compadd - $PREFIX*; }

# New-style -- loaded by 'compinit'
# _complete_files () {
#   eval "$_comp_setup"
#   _main_complete _files
# }
# compdef -k _complete_files complete-word '^X/'

# Bind last executed command as 'abyss'. Reset: apply to 'abyss'
zle -N set-fast-exec-cmd set_fast_exec_cmd
function set_fast_exec_cmd {
    local cmd="${*:-${BUFFER:-$(fc -ln -1)}}"
    bindkey  -s ',m' "^U$cmd\n"
    bindkey -as ',m' "S$cmd\n"
    (($#)) || printf "\nSaved: '%s'\n" "$cmd"
    # WARNING: don't output -- for key-mix setting? or eval "$cmd?"
}

### TRAPS ###

# Save to history on <C-c> alongside interrupt
function TRAPINT() {
    if [[ -n "$BUFFER" ]]; then
        zle && print -s -r -- $BUFFER && return $1  # Default
    else
        return 1
    fi
}
