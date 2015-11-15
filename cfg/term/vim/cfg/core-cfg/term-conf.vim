" Toggle auto-indenting manually (works in INSERT too)
set pastetoggle=<F2>
nnoremap <unique> <Leader>tP :set paste! paste?<CR>
" Auto-disable paste.
au MyAutoCmd InsertLeave * if &paste | set nopaste | endif


" DISABLED: necessary only for bare urxvt w/o remappings in resources
" masquerade rxvt as xterm so that arrow keys work correctly in insert mode
" if &term =~ 'rxvt'
"   execute 'set term=' . substitute(&term, '\vrxvt(-unicode)?', 'xterm', '')
" endif


" Infinite wait on mappings, but timeout on keycodes (like <\e..>)
" WARNING: you must eliminate clushing keymaps like ',x' and ',xy'
set notimeout ttimeout
" Leave insert mode quickly
augroup FastEscape
  autocmd!
  au InsertEnter * set timeoutlen=0 ttimeoutlen=0
  au InsertLeave * set timeoutlen=1000 ttimeoutlen=32
augroup END

" DISABLED: arrows and other escaped keys will be broken in insert mode
" set noesckeys " (Hopefully) removes the delay when hitting esc in insert mode


"{{{1 Mouse in Term ============================
if !has('nvim') && has('mouse')
  set mouse=a           " support for mouse wheel and clicks
  if has('mouse_sgr') || v:version > 703 || v:version == 703 && has('patch632')
    set ttymouse=sgr
  else
    set ttymouse=xterm2
  endif
  " Paste: USE 'set paste' on F2 before inserting
  nnoremap <MiddleMouse> "+p
  xnoremap <MiddleMouse> "+p
  inoremap <MiddleMouse> <C-r><C-o>+
  cnoremap <MiddleMouse> <C-r>+
endif
