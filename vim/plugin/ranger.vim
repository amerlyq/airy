" @license MIT, (c) amerlyq, 2017
if &cp||exists('g:loaded_ranger')|finish|else|let g:loaded_ranger=1|en

" augroup ranger_chooser
"   autocmd!
"   au BufEnter * if isdirectory(expand('<afile>'))| call ranger#do([expand('<afile>')]) |en
" augroup END
" CHECK: if we loose edit by ssh://
" let g:loaded_netrwPlugin = 'disable'


" THINK: open from under cursor, visual selection, yank buffer
command! -bang -bar -nargs=? -range
    \ RangerChooser  call ranger#command(<bang>0, <f-args>)

if !get(g:, 'ranger_nomap')
  noremap <unique>  <Leader>f :<C-U>RangerChooser<CR>
  noremap <unique>  <Leader>F :<C-U>RangerChooser!<CR>
  noremap <unique> g<Leader>f :<C-U>RangerChooser <cfile><CR>
  noremap <unique> g<Leader>F :<C-U>RangerChooser!<cfile><CR>
endif
