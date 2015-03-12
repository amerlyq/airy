set hidden     " lets you switch buffers without saving
set splitright " focus new window after vertical splitting
set splitbelow " focus new window after horizontal splitting

" Set minimum window size to 79x8
set winheight=8
set winminheight=8
set winwidth=79
set winminwidth=15

" switching
noremap  zh  <C-W>h
noremap  zj  <C-W>j
noremap  zk  <C-W>k
noremap  zl  <C-W>l

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

" collapse other windows
" nnoremap <Leader>0 <C-W><Bar><C-W>_
" all windows equal size
" nnoremap <Leader>9 <C-W>=
" close other windows
" nnoremap <Leader>1 <C-W>o
" close current window
" nnoremap <Leader>4 <C-W>c


" Symmetrical binding to 'gt' for buffers  (12gb -- open buffer 12)
nnoremap <unique> gb :<C-U><C-R>=v:count1<CR>b<CR>
" Toggle to last edited buffer/file
nnoremap <unique> \` :b#<CR>

" Direct pick tab on <M-\d> or buffer on <leader>\d
for idx in range(1,10)
    exec "map <unique> <M-". string(idx % 10) ."> ". idx ."gt"
    exec "map <unique>  \\". string(idx % 10) ."  ". idx ."gb"
endfor
