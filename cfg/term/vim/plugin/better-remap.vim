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


command! -bar -nargs=0 -range=% RecoverRemove  call s:RecoverRemove()
fun! s:RecoverRemove()
  redir => _|sw|redir END
  let _ = substitute(_,'[\r\n]','','g')
  let _ = _[:-2].nr2char(char2nr(_[-1:])+1)
  if confirm("RM? "._,"&Y\n&n",1)==1
    echo (delete(_)?'NOT': 'OK')
  endif
endf
" command! -bar -nargs=0 -range=% RecoverDiff  tabnew|preview|diff
" command! -bar -nargs=0 -range=% RecoverEnd  tabclose|RecoverRemove
