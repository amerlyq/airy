nnoremap <Leader>dD :diffoff<Enter>
nnoremap <Leader>dd :diffupdate<Enter>
nnoremap <Leader>dt :diffthis<Enter>
nnoremap <Leader>dT :DiffOrig<Enter>

if &diff
  "---------------------------------------------------------------------------
  " Randy Morris' convenient diff mappings
  " http://www.reddit.com/r/vim/comments/kz84u#c2oiq1a
  "---------------------------------------------------------------------------

  " allows you to 'do undo', or in other words 'undo a change in the opposite
  " window'
  nnoremap du :wincmd w <bar> undo <bar> wincmd w <bar> diffupdate<enter>

  " updates the highlighting and folding when undoing a change
  nnoremap u :undo <bar> diffupdate<enter>

  " use space and backspace to jump forward/backward through differences
  nnoremap <space> :normal! ]c<enter>
  nnoremap <backspace> :normal! [c<enter>

  " allows you to 'put' and 'obtain' changes in visual mode for the instances
  " where multiple changes are on concurrent lines and you don't want to make
  " both changes
  vnoremap p :diffput <bar> diffupdate<enter>
  vnoremap o :diffget <bar> diffupdate<enter>
endif
