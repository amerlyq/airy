" Leader '\' {{{
let s:leader = g:mapleader
let mapleader = "\\"

map <unique> <Leader>swp <Plug>SaveWinPosn
map <unique> <Leader>rwp <Plug>RestoreWinPosn

let mapleader = s:leader
" }}}
