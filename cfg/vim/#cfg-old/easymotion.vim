" Leader 'q' {{{
let s:leader = g:mapleader
let mapleader = "q"

" Easymotion-search (before: ,.)
nmap <unique> <silent> <Leader> <Plug>(easymotion-prefix)
omap <unique> <silent> <Leader> <Plug>(easymotion-prefix)

nmap <unique> <Leader>n <Plug>(easymotion-next)
nmap <unique> <Leader>p <Plug>(easymotion-prev)


let mapleader = s:leader
" }}}
