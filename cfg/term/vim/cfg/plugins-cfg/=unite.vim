" Mappings

" Toggle {{{
nnoremap <Leader>tt :TagbarToggle<CR>
let g:lt_location_list_toggle_map = '\l'
let g:lt_quickfix_list_toggle_map = '\q'

" }}}


" Widgets {{{

" UndoTree
nnoremap <silent> <Leader>u :<C-U>UndotreeToggle<CR>

" }}}


" Unite {{{
" Replaces fuzzyfinder, recursive
nnoremap <leader>o :<C-u>Unite -buffer-name=files file_rec/async:!<cr>

" Focus the current fold by closing all others
" nnoremap [unite]z mzzM`zzv

" Leader '\' {{{
let s:leader = g:mapleader
let mapleader = "\\"

" nnoremap <leader>f :<C-u>VimFiler<cr>
nnoremap <leader>f :<C-u>Unite -buffer-name=files file<cr>
nnoremap <leader>b :<C-u>Unite -quick-match -buffer-name=buffers buffer bookmark<cr>
nnoremap <leader>/ :<C-u>Unite -buffer-name=grep grep:.<cr>
nnoremap <leader>l :<C-u>Unite -buffer-name=lines line<cr>
nnoremap <leader>; :<C-u>Unite -buffer-name=commands command<cr>
nnoremap <leader>: :<C-u>Unite -buffer-name=commands history/command<cr>

nnoremap <leader>m :<C-u>Unite -buffer-name=mrus file_mru<cr>
nnoremap <leader>y :<C-u>Unite -buffer-name=yanks history/yank<cr>
nnoremap <leader>u :<C-u>Unite -buffer-name=Outline outline<cr>

" <leader>h help
" -u outline
" -n file/new

let mapleader = s:leader
" }}}
