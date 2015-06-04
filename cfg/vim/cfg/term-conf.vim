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

" DISABLED: arrows and other escaped keys will be breaked in insert mode
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


" For tmux: disable bkgd color erase to adequate bkgd color
set t_ut=
" Change cursor in insert-mode
if &term =~ "^xterm\\|rxvt"
  "" There are sequence to change color, but not the one to restore to default

  " let &t_EI = "\<Esc>]12;white\x7"
  " silent !echo -ne "\033]12;white\007"
  " let &t_SI = "\<Esc>]12;orange\x7"
  " "" reset cursor when vim exits " use \003]12;gray\007 for gnome-terminal
  " autocmd VimLeave * silent !echo -ne "\033]112\007"

  "" Cursor shape.
  let &t_EI .= "\<Esc>[2 q"
  let &t_SI .= "\<Esc>[4 q"
  " [01,2]-> [blinking,solid] block
  " [3,4] -> [blinking,solid] underscore
  " [5,6] -> [blinking,solid] vbar (only in xterm > 282)

  "" Another variant
    " let &t_EI = "\<Esc>]12;white\x9c"
    " let &t_SI = "\<Esc>]12;orange\x9c"
    " "We normally start in cmd-mode
    " silent !echo -e "\e]12;white\x9c"
endif

