exe "fun! IsWindows()\nreturn".(has('win32') || has('win64'))."\nendf"
exe "fun! IsAndroid()\nreturn".('android'==#$USER&&$TERM=~#'^xterm')."\nendf"

exe "fun! IsCygwin() \nreturn". has('win32unix') ."\nendf"
exe "fun! IsMac()    \nreturn".(!IsWindows() && !IsCygwin() && (
    \ has('mac') || has('macunix') || has('gui_macvim') || (
    \ !executable('xdg-open') && system('uname') =~? '^darwin')))."\nendf"
exe "fun! IsSudo()   \nreturn".($SUDO_USER !=# '' && $USER !=# $SUDO_USER &&
    \ $HOME !=# expand('~'.$USER) && $HOME ==# expand('~'.$SUDO_USER))."\nendf"


"{{{1 Cross-wrappers ==========
let s:py3 = ((has('python3')&&get(g:,'pymode_python','')!=#'python')?'3': '')
exe 'comm! -nargs=1 PythonI python'.s:py3.' <args>'
exe 'comm! -nargs=1 PythonF py'.s:py3.'file <args>'
exe "fun! IPythonPyeval(arg)\nreturn py".s:py3."eval (a:arg)\nendf"
exe 'PythonI PY3 = '.(s:py3!=#'' ? 'True' : 'False')
