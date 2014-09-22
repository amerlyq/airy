set hidden " lets you switch buffers without saving

" close current buffer while retaining window
nnoremap <Leader>$ :execute 'bnext<Bar>bdelete' bufnr('%')<cr>

" reload current buffer while discarding changes
"nnoremap <Leader>e :edit!<cr>



set splitright " focus new window after vertical splitting
set splitbelow " focus new window after horizontal splitting

" focus adjacent window
nnoremap <A-PageUp> <C-W>W
nnoremap <A-PageDown> <C-W>w

" split current window
nnoremap <Leader>2 <C-W>s
nnoremap <Leader>3 <C-W>v

" collapse other windows
nnoremap <Leader>0 <C-W><Bar><C-W>_

" all windows equal size
nnoremap <Leader>9 <C-W>=

" close other windows
nnoremap <Leader>1 <C-W>o

" close current window
nnoremap <Leader>4 <C-W>c
