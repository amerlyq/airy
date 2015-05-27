" Leader '\' {{{
let s:leader = g:mapleader
let mapleader = "\\"

nnoremap <unique> <Leader>di DrawIt!
" map <unique> <Leader>swp <Plug>SaveWinPosn
" map <unique> <Leader>rwp <Plug>RestoreWinPosn


"To stop vim-rooter changing directory automatically
let g:rooter_manual_only = 1
nmap <unique> <silent> <Leader>cd <Plug>RooterChangeToRootDirectory
" Change Working Directory to that of the current file
noremap <unique> <silent> <Leader>cw :lcd %:p:h<CR>

let mapleader = s:leader
" }}}


"" Focus on content -- 'chrisbra/NrrwRgn'
" Create two region buffers and use :diffthis --> instead of LineDiff
" Multiselection in new buffer! :v/^#/NRP | NRM
" Tip -- completely delete blocks you don't want to change.

" let g:nrrw_rgn_nohl = 1
" split buffer in same window
let g:nrrw_topbot_leftright = 'botright'
nmap <unique> <Leader>n <Plug>NrrwrgnDo
xmap <unique> <Leader>n <Plug>NrrwrgnDo
omap <unique> <Leader>n <Plug>NrrwrgnDo
" separate buffer
nmap <unique> <Leader>N <Plug>NrrwrgnBangDo
xmap <unique> <Leader>N <Plug>NrrwrgnBangDo
omap <unique> <Leader>N <Plug>NrrwrgnBangDo
" CMD:
