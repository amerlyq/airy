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


"{{{ CMDS =====
command! -bar -nargs=0 -range=% RecoverRemove  call s:RecoverRemove()
command! -bar -nargs=0 -range=% RecoverDiff  call s:DiffRecover()
command! -bar -nargs=0 -range=% RecoverEnd  call s:DiffRecoverEnd()


" BUG: undo don't work after writing new recover
" DEV: auto-cancel ':recover' if I haven't saved (don't want to apply changes)
" SEE: how it was done in Linediff

" TODO: use 'q' if responded 'pid' exists and file differs
" ELSE: use 'e' if no pid -- and jump to diff
" ELSE: if file the same -- use 'o' anyway and 'modifiable' off -- to warn user it was opened
" ALSO: show notify 'it's already opened' (by !r.n and/or :echom)
" ALSO: use 'cmp' before vimdiff to accelerate diffs on big > 1MB files
" BUT: can we 'cmp' with 'swp'?!

"{{{ IMPL =====

fun! s:RecoverRemove() abort
  redir => _|sw|redir END
  let _ = substitute(_,'[\r\n]','','g')
  let _ = _[:-2].nr2char(char2nr(_[-1:])+1)
  if confirm("RM? "._,"&Y\n&n",1)==1
    echo (delete(_)?'NOT': 'OK')
  endif
  if &l:swf && !empty(bufname(''))
    " Reset swapfile to use .swp extension
    silent setl noswapfile swapfile
  endif
endf

fun! s:DiffRecover() abort
  call s:RecoverUnhook()
  tabnew | set bt=nofile
  file =Origin=
  read ++edit # | 0d_ | diffthis
  vsplit # | silent recover | diffthis
  let t = tabpagenr()
  exe "au recover_swap TabLeave ".t." call s:DiffRecoverEnd(".t.")"
  exe "au recover_swap QuitPre {=Origin=,".expand('%:p')."} call s:DiffRecoverEnd(".t.")"
  exe "au recover_swap BufDelete {=Origin=,".expand('%:p')."} call s:DiffRecoverEnd(".t.")"
endf

fun! s:DiffRecoverEnd(t) abort
  call s:RecoverUnhook()
  bdelete =Origin= " TODO: Check if exists
  windo diffoff
  exe 'tabclose' a:t
  call s:RecoverRemove()
  " DEV: remove read-only attribute if choice was to delete swap
endf


"{{{ HOOKS =====
fun! s:RecoverHook() abort
  if getfsize(expand('%:p')) > 1024*1024| return |en
  au recover_swap BufEnter * call s:DiffRecover()
  let v:swapchoice='o'
endf

fun! s:RecoverUnhook() abort
  augroup recover_swap
    au!
    au SwapExists * call s:RecoverHook()
  augroup END
endf

call s:RecoverUnhook()
