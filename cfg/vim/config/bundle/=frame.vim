" Leader '\' {{{
let s:leader = g:mapleader
let mapleader = "\\"

map <Leader>di <Plug>DrawItStart
map <Leader>ds <Plug>DrawItStop

let mapleader = s:leader
" }}}
