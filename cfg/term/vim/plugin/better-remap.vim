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
" TODO: auto-choose '[E]dit' and then do 'DiffRecover'
"   -- if swap exists -- on 'Edit anyway' load RecoverDiff automatically
"   -- hook on 'recovery window/tab quit' to do RecoverEnd automatically
"   -- always open new tab with split -- so I could use it from existing session
" SEE: how it was done in Linediff

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
  au recover_swap BufEnter * call s:DiffRecover()
endf

fun! s:RecoverUnhook() abort
  augroup recover_swap
    au!
    " TODO: use 'q' if responded 'pid' exists, else:
    au SwapExists * exe "let v:swapchoice='o' | call s:RecoverHook()"
  augroup END
endf

call s:RecoverUnhook()
