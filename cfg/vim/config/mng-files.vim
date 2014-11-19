" Workflow manipulation {{{
" http://vim.wikia.com/wiki/Mapping_keys_in_Vim_-_Tutorial_%28Part_3%29

" SAVE: {koi8-r, imb866, cp-1251, utf8, reg:utf-16le, :set fenc=utf8}
noremap <Leader>S :<C-U>write ++enc=utf8<CR>
noremap <Leader><C-S> :saveas<Space>

" Ag, Save, Drop, File,
noremap <Leader>a :<C-U>Ag<CR>
noremap <Leader>f :<C-U>RangerChooser<CR>
noremap <Leader>s :<C-U>w<CR>
" noremap <Leader>S :<C-U>wa<CR>
noremap <Leader>d :<C-U>q<CR>
noremap <Leader>D :<C-U>qa<CR>

"-----

" Close current buffer while retaining window
function! s:BufDelSafe()
  if bufnr('%') == bufnr('$')
    exec 'bprev<Bar>bdelete ' . bufnr('%')
  else
    exec 'bnext<Bar>bdelete ' . bufnr('%')
  endif
endfunction
command! -bar Safebd call <SID>BufDelSafe()
nnoremap <Leader>x :<C-U>Safebd<CR>
" noremap <Leader>x :<C-U>exec 'bnext<Bar>bdelete' bufnr('%')<CR>

" reload current buffer while discarding changes
"nnoremap <Leader>e :edit!<cr>
" }}}
