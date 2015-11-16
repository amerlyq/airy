exe "fun! IsWindows()\nreturn".(has('win32') || has('win64'))."\nendf"
exe "fun! IsCygwin() \nreturn". has('win32unix') ."\nendf"
exe "fun! IsMac()    \nreturn".(!IsWindows() && !IsCygwin() && (
    \ has('mac') || has('macunix') || has('gui_macvim') || (
    \ !executable('xdg-open') && system('uname') =~? '^darwin')))."\nendf"
exe "fun! IsSudo()   \nreturn".($SUDO_USER !=# '' && $USER !=# $SUDO_USER &&
    \ $HOME !=# expand('~'.$USER) && $HOME ==# expand('~'.$SUDO_USER))."\nendf"


"{{{1 Maps helpers ==========
fun! RetainPos(cmd)
  " ALT line("."), col(".")
  let l:pos = getcurpos()
  silent! exe a:cmd
  call setpos('.', l:pos)
endf

fun! Map_nxo(fr, to, ...)
  for m in split(a:0>1 ? a:2 : 'nxo', '\zs')
    " echo m.(a:0>0 ? a:1 : 'map').' <silent><unique> '. a:fr .' '. a:to
    exe m.(a:0>0 ? a:1 : 'map').' <silent><unique> '. a:fr .' '. a:to
  endfor
endfun
