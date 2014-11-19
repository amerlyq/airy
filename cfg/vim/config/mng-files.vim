" Workflow manipulation {{{
" http://vim.wikia.com/wiki/Mapping_keys_in_Vim_-_Tutorial_%28Part_3%29

" SAVE: {koi8-r, imb866, cp-1251, utf8, reg:utf-16le, :set fenc=utf8}
noremap <unique> <Leader>S :<C-U>write ++enc=utf8<CR>
noremap <unique> <Leader><C-S> :saveas<Space>

" ???, Save, Drop, File,
noremap <unique> <Leader>f :<C-U>RangerChooser<CR>
noremap <unique> <Leader>s :<C-U>w<CR>
" noremap <unique> <Leader>S :<C-U>wa<CR>
noremap <unique> <Leader>d :<C-U>q<CR>
noremap <unique> <Leader>D :<C-U>qa<CR>
" Close current buffer while retaining window
noremap <unique> <Leader>x :<C-U>exec 'bnext<Bar>bdelete' bufnr('%')<CR>

" reload current buffer while discarding changes
"nnoremap <Leader>e :edit!<cr>
" }}}
