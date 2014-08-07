set hidden " lets you switch buffers without saving

" switch to adjacent buffer in current window
nnoremap <C-PageUp>    <Esc>:bprev<CR>
nnoremap <C-PageDown>  <Esc>:bnext<CR>
nnoremap <M-,>         <Esc>:bprev<CR>
nnoremap <M-.>         <Esc>:bnext<CR>


" close current buffer while retaining window
nnoremap <Leader>$ :execute 'bnext<Bar>bdelete' bufnr('%')<cr>

" reload current buffer while discarding changes
"nnoremap <Leader>e :edit!<cr>
