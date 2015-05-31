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


" ============== NrrwRgn ============== {{{1
":: Focus on content in split window
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


" ============== vim-altr ============== {{{1
":: Toggle between alternative files (.h, .cpp, ...)
nmap <unique> ]f  <Plug>(altr-forward)
nmap <unique> [f  <Plug>(altr-back)
command! A  call altr#forward()
" ALT: map <F4> :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>
