"" automatically leave insert mode after 'updatetime' milliseconds of inaction
" au CursorHoldI * stopinsert
"" set 'updatetime' to 2 seconds when in insert mode, and restore back on leave
" au InsertEnter * let updaterestore=&updatetime | set updatetime=3000
" au InsertLeave * let &updatetime=updaterestore


" leave insert mode quickly
" if ! has('gui_running')
" set ttimeoutlen=10

set noesckeys " (Hopefully) removes the delay when hitting esc in insert mode
augroup FastEscape
  autocmd!
  au InsertEnter * set timeoutlen=0
  au InsertLeave * set timeoutlen=1000
augroup END
" endif

" Don't works. Pity.
" set timeout timeoutlen=1000 ttimeoutlen=100

