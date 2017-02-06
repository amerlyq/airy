set hidden      " lets you switch buffers without saving
set splitright  " focus new window after vertical splitting
set splitbelow  " focus new window after horizontal splitting

" Use on each window of split, to scroll in sync
nnoremap <unique> [Toggle]b :setl scrollbind! scb?<CR>

" switching
noremap <unique> zh  <C-W>h
noremap <unique> zj  <C-W>j
noremap <unique> zk  <C-W>k
noremap <unique> zl  <C-W>l

" switch to adjacent buffer in current window
noremap <unique> gh  :<C-U>bprev<CR>
noremap <unique> gl  :<C-U>bnext<CR>
noremap <unique> gH  :<C-U>bfirst<CR>
noremap <unique> gL  :<C-U>blast<CR>
