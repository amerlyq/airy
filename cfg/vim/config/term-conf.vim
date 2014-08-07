" masquerade rxvt as xterm so that arrow keys work correctly in insert mode
if &term =~ 'rxvt'
  execute 'set term=' . substitute(&term, '\vrxvt(-unicode)?', 'xterm', '')
endif

" disable bkgd color erase to adequate bkgd color in tmux
set t_ut=

" Change cursor in insert-mode
if &term =~ "^xterm\\|rxvt"
  " let &t_EI = "\<Esc>]12;white\x7"
  " silent !echo -ne "\033]12;white\007"
  " let &t_SI = "\<Esc>]12;orange\x7"
  " "" reset cursor when vim exits " use \003]12;gray\007 for gnome-terminal
  " autocmd VimLeave * silent !echo -ne "\033]112\007"
  "" There are sequence to change color, but not the one to restore to default

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
