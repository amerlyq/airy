autocmd BufReadPost fugitive://* set bufhidden=delete

nnoremap <silent> <leader>gs :<C-u>Gstatus<cr>
nnoremap <silent> <leader>gl :<C-u>Glog<cr>
nnoremap <silent> <leader>gd :<C-u>Gdiff<cr>
nnoremap <silent> <leader>gw :<C-u>Gwrite<cr>
nnoremap <silent> <leader>gb :<C-u>Gblame<cr>
