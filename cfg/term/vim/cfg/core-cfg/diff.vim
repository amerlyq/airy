" NOTE diffopt=iwhite  to find what is -common- between buffers

nnoremap [Frame]dD :diffoff<CR>
nnoremap [Frame]dd :diffupdate<CR>
nnoremap [Frame]dt :diffthis<CR>
nnoremap [Frame]dT :DiffOrig<CR>
" nnoremap <silent> <expr> ,d ":\<C-u>".(&diff?"diffoff":"diffthis")."\<CR>"

" Disable paste.
au MyAutoCmd InsertLeave * if &l:diff | diffupdate | endif

" Randy Morris' convenient diff mappings
" http://www.reddit.com/r/vim/comments/kz84u#c2oiq1a
if &diff
  " allows you to 'do undo' ('undo a change in the opposite window')
  nnoremap du :wincmd w <Bar> undo <Bar> wincmd w <Bar> diffupdate<enter>
  " updates the highlighting and folding when undoing a change
  nnoremap u :undo <Bar> diffupdate<CR>

  " [c  Jump backwards to the previous start of a change.
  " ]c  Jump forwards to the next start of a change.
  " USE space and backspace to jump forward/backward through differences
  " DISABLED: conflicts with my Space leader and vim-sneak
  " nnoremap <space> :normal! ]c<CR>
  " nnoremap <backspace> :normal! [c<CR>

  " USAGE: put/obtain only vsel instead of whole diff chunk
  vnoremap dp :diffput <Bar> diffupdate<CR>
  vnoremap do :diffget <Bar> diffupdate<CR>
endif


" Display diff with the file.
command! -nargs=1 -complete=file Diff vertical diffsplit <args>
" Disable diff mode.
command! -nargs=0 DiffEnd setlocal nodiff noscrollbind wrap
" Use :DiffOrig to see the differences between the current buffer and the
" file it was loaded from. Use :diffupdate then
command! DiffOrig vert new | set bt=nofile | r ++edit # | 0d_
    \ | diffthis | wincmd p | diffthis
