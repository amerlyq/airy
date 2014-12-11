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
" nnoremap <Leader>2 <C-W>s
" nnoremap <Leader>3 <C-W>v

" collapse other windows
" nnoremap <Leader>0 <C-W><Bar><C-W>_
" all windows equal size
" nnoremap <Leader>9 <C-W>=
" close other windows
" nnoremap <Leader>1 <C-W>o
" close current window
" nnoremap <Leader>4 <C-W>c

" Leader '\' {{{
let s:leader = g:mapleader
let mapleader = "\\"

" Toggle to last edited buffer/file
nnoremap <Leader>` :b#<CR>

nnoremap <Leader>1 :1b<CR>
nnoremap <Leader>2 :2b<CR>
nnoremap <Leader>3 :3b<CR>
nnoremap <Leader>4 :4b<CR>
nnoremap <Leader>5 :5b<CR>
nnoremap <Leader>6 :6b<CR>
nnoremap <Leader>7 :7b<CR>
nnoremap <Leader>8 :8b<CR>
nnoremap <Leader>9 :9b<CR>
nnoremap <Leader>0 :10b<CR>

let mapleader = s:leader
" }}}
