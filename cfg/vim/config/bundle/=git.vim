" Leader '\' {{{
let s:leader = g:mapleader
let mapleader = "\\"


" Fugitive: {{{
autocmd BufReadPost fugitive://* set bufhidden=delete

nnoremap <silent> <leader>gs :<C-u>Gstatus<cr>
nnoremap <silent> <leader>gl :<C-u>Glog<cr>
nnoremap <silent> <leader>gd :<C-u>Gdiff<cr>
nnoremap <silent> <leader>gw :<C-u>Gwrite<cr>
nnoremap <silent> <leader>gb :<C-u>Gblame<cr>
" }}}

" Gitv: {{{
nmap <leader>gv :Gitv --all<cr>
nmap <leader>gV :Gitv! --all<cr>
vmap <leader>gV :Gitv! --all<cr>
" }}}


let mapleader = s:leader
" }}}
