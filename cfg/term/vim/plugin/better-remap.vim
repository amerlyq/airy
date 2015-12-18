if &cp||exists('g:loaded_remaps')|finish|else|let g:loaded_remaps=1|endif

" Remaps gm so the cursor is moved to the middle of the current physical line.
" Any leading or trailing whitespace is ignored: the cursor moves to the middle
" of the text between the first and last non-whitespace characters.
function! s:Gm()
  execute 'normal! ^'
  let first_col = virtcol('.')
  execute 'normal! g_'
  let last_col  = virtcol('.')
  execute 'normal! ' . (first_col + last_col) / 2 . '|'
endfunction
nnoremap <silent> gm :call <SID>Gm()<CR>
onoremap <silent> gm :call <SID>Gm()<CR>
