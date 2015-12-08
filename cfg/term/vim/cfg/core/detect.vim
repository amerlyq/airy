exe "fun! IsWindows()\nreturn".(has('win32') || has('win64'))."\nendf"
exe "fun! IsAndroid()\nreturn".('android'==#$USER&&$TERM=~#'^xterm')."\nendf"

exe "fun! IsCygwin() \nreturn". has('win32unix') ."\nendf"
exe "fun! IsMac()    \nreturn".(!IsWindows() && !IsCygwin() && (
    \ has('mac') || has('macunix') || has('gui_macvim') || (
    \ !executable('xdg-open') && system('uname') =~? '^darwin')))."\nendf"
exe "fun! IsSudo()   \nreturn".($SUDO_USER !=# '' && $USER !=# $SUDO_USER &&
    \ $HOME !=# expand('~'.$USER) && $HOME ==# expand('~'.$SUDO_USER))."\nendf"


"{{{1 Cross-wrappers ==========
if has('python3') && get(g:, 'pymode_python', '') !=# 'python'
  command! -nargs=1 PythonI python3 <args>
  command! -nargs=1 PythonF py3file <args>
  PythonI PY3 = True
  exe "fun! IPythonPyeval(arg)\nreturn py3eval (a:arg)\nendf"
elseif has('python')
  command! -nargs=1 PythonI python <args>
  command! -nargs=1 PythonF pyfile <args>
  PythonI PY3 = False
  exe "fun! IPythonPyeval(arg)\nreturn pyeval (a:arg)\nendf"
else
  echom "No python support. Your bad, plugins can't be loaded."
endif
