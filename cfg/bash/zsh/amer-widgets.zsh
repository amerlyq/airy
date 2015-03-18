# SEE
#   print -s : http://linux.die.net/man/1/zshbuiltins

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

