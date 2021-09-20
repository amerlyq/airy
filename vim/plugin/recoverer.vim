" @license MIT, (c) amerlyq, 2015,2021
if &cp||exists('g:loaded_recoverer')|finish|else|let g:loaded_recoverer=1|en

augroup recoverer
  au!
  "" TRY:USE: latest neovim defaults
  " au SwapExists * call recoverer#on_swap()
  au SwapExists * let v:swapchoice = "o"
augroup END

"{{{ CMDS =====
" command! -bar -nargs=0 -range=% RecovererRemove call recoverer#remove()
" command! -bar -nargs=0 -range=% RecovererDiff   call recoverer#diffbeg()
" command! -bar -nargs=0 -range=% RecovererEnd    call recoverer#diffend()
