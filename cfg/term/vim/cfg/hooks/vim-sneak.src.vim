"  - s<Enter> repeats (even off-screen), <Tab> skips to next 56 matches,
"  - any key that is _not_ a target label, performs its normal-mode function
"  - text in |folds| is ignored by streak-mode
"  - return to your original location via |CTRL-O| or |``|
"  - if `s` is prefixed with a [count] then sneak-vertical-scope invoked

let g:sneak#streak = 1        " Use labels, Space/Esc to choose current
let g:sneak#s_next = 1        " Use s/S immediately after sneak to next/prev
let g:sneak#f_reset = 0
let g:sneak#t_reset = 0
let g:sneak#use_ic_scs = 1    " Respect 'ignorecase' and 'smartcase'
let g:sneak#textobject_z = 0  " No default z-operator (I use q-operator)
let g:sneak#streak_esc = ' '  " FIXED: resolves overlapping with '[Space]'

" BAD: if hasmapto('[Space]') | let g:sneak#streak_esc = '[Space]' | endif
