" Toggle auto-indenting manually (works in INSERT too)
set pastetoggle=<F2>


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


" Suppress move-left of cursor when leaving insert mode
"   http://vim.wikia.com/wiki/Prevent_escape_from_moving_the_cursor_one_character_to_the_left
let CursorColumnI = 0 "the cursor column position in INSERT
augroup StayFixed
  autocmd!
  au InsertEnter * let CursorColumnI = col('.')
  au CursorMovedI * let CursorColumnI = col('.')
  au InsertLeave * if col('.') != CursorColumnI | call cursor(0, col('.')+1) | endif
augroup END
