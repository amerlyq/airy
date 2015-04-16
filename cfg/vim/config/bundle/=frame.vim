" Leader '\' {{{
let s:leader = g:mapleader
let mapleader = "\\"

nnoremap <Leader>di DrawIt!
" map <unique> <Leader>swp <Plug>SaveWinPosn
" map <unique> <Leader>rwp <Plug>RestoreWinPosn


"To stop vim-rooter changing directory automatically
let g:rooter_manual_only = 1
nmap <silent> <Leader>cd <Plug>RooterChangeToRootDirectory
" Change Working Directory to that of the current file
noremap <silent> <Leader>cw :lcd %:p:h<CR>


let mapleader = s:leader
" }}}
