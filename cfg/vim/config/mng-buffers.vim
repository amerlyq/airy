set hidden     " lets you switch buffers without saving
set splitright " focus new window after vertical splitting
set splitbelow " focus new window after horizontal splitting

" Set minimum window size to 79x8
set winheight=8
set winminheight=8
set winwidth=79
set winminwidth=15

" switch with magnifying
noremap  zh  <C-W>h<C-W>_
noremap  zj  <C-W>j<C-W>_
noremap  zk  <C-W>k<C-W>_
noremap  zl  <C-W>l<C-W>_

" Move between folds
noremap  zJ  zj
noremap  zK  zk

" switch to adjacent buffer in current window
noremap  gh  :<C-U>bprev<CR>
noremap  gl  :<C-U>bnext<CR>
noremap  gH  :<C-U>bfirst<CR>
noremap  gL  :<C-U>blast<CR>


" focus adjacent window
" nnoremap <A-PageUp> <C-W>W
" nnoremap <A-PageDown> <C-W>w
" split current window
" :vs, :sp
" nnoremap <Leader>2 <C-W>s
" nnoremap <Leader>3 <C-W>v

" collapse other windows
nnoremap <Leader>0 <C-W><Bar><C-W>_
" all windows equal size
nnoremap <Leader>9 <C-W>=
" close other windows
nnoremap <Leader>1 <C-W>o
" close current window
" nnoremap <Leader>4 <C-W>c

