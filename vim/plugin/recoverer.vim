finish  " TRY:USE: latest neovim defaults
" @license MIT, (c) amerlyq, 2015
if &cp||exists('g:loaded_recoverer')|finish|else|let g:loaded_recoverer=1|en

"{{{ CMDS =====
command! -bar -nargs=0 -range=% RecovererRemove call recoverer#remove()
command! -bar -nargs=0 -range=% RecovererDiff   call recoverer#diffbeg()
command! -bar -nargs=0 -range=% RecovererEnd    call recoverer#diffend()

augroup recoverer
  au!
  au SwapExists * call recoverer#on_swap()
augroup END
