nnoremap \dD :diffoff<Enter>
nnoremap \dd :diffupdate<Enter>
nnoremap \dt :diffthis<Enter>
nnoremap \dT :DiffOrig<Enter>
" nnoremap <silent> <expr> ,d ":\<C-u>".(&diff?"diffoff":"diffthis")."\<CR>"

" Disable paste.
autocmd MyAutoCmd InsertLeave * if &l:diff | diffupdate | endif

if &diff
  "---------------------------------------------------------------------------
  " Randy Morris' convenient diff mappings
  " http://www.reddit.com/r/vim/comments/kz84u#c2oiq1a
  "---------------------------------------------------------------------------
  set wrap
  set nocursorline      " to not color overlap with highlighted diff regions

  " allows you to 'do undo', or in other words 'undo a change in the opposite
  " window'
  nnoremap du :wincmd w <bar> undo <bar> wincmd w <bar> diffupdate<enter>

  " updates the highlighting and folding when undoing a change
  nnoremap u :undo <bar> diffupdate<enter>

  " [c  Jump backwards to the previous start of a change.
  " ]c  Jump forwards to the next start of a change.
  " USE space and backspace to jump forward/backward through differences
  nnoremap <space> :normal! ]c<CR>
  nnoremap <backspace> :normal! [c<CR>

  " allows you to 'put' and 'obtain' changes in visual mode for the instances
  " where multiple changes are on concurrent lines and you don't want to make
  " both changes
  vnoremap p :diffput <bar> diffupdate<enter>
  vnoremap o :diffget <bar> diffupdate<enter>

else
  " setup for non-diff mode
  set cursorline      " highlight currently focused line
endif


" Display diff with the file.
command! -nargs=1 -complete=file Diff vertical diffsplit <args>
" Disable diff mode.
command! -nargs=0 DiffEnd setlocal nodiff noscrollbind wrap
" Use :DiffOrig to see the differences between the current buffer and the
" file it was loaded from. Use :diffupdate then
command! DiffOrig vert new | set bt=nofile | r ++edit # | 0d_
    \ | diffthis | wincmd p | diffthis
