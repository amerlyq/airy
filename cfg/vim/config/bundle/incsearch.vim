
let g:indexed_search_mappings=1
" nnoremap /  :ShowSearchIndex<CR>/
" nnoremap ?  :ShowSearchIndex<CR>?

nnoremap <silent>* *N:ShowSearchIndex<CR>
nnoremap <silent># #N:ShowSearchIndex<CR>
" With unfold
nnoremap <silent>n nzv:ShowSearchIndex<CR>
nnoremap <silent>N Nzv:ShowSearchIndex<CR>

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)
