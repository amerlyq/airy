" True colors in 'hi!' nvim>=v1.5 (160511) OR vim>=v7.4.1770 (1799?)
" FIXME: disable in 'tmux <v2.2' ALT: disable Tc support inside tmux.conf
if has('termguicolors')
  set termguicolors
  " FIXED: st + vim8  OR:USE: s/;/:/g for other non-xterm
  if !has('nvim')
    " || (v:version > 704 || (v:version == 704 && has('patch1770')))
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  en
en

exe "fun! IsWindows()\nreturn".(has('win32') || has('win64'))."\nendf"
exe "fun! IsAndroid()\nreturn".('android'==#$USER&&$TERM=~#'^xterm')."\nendf"

exe "fun! IsCygwin() \nreturn". has('win32unix') ."\nendf"
exe "fun! IsMac()    \nreturn".(!IsWindows() && !IsCygwin() && (
    \ has('mac') || has('macunix') || has('gui_macvim') || (
    \ !executable('xdg-open') && system('uname') =~? '^darwin')))."\nendf"
exe "fun! IsSudo()   \nreturn".($SUDO_USER !=# '' && $USER !=# $SUDO_USER &&
    \ $HOME !=# expand('~'.$USER) && $HOME ==# expand('~'.$SUDO_USER))."\nendf"


"{{{1 Cross-wrappers ==========
" BUG: can't comment s:py3
let s:py3 = ((has('python3')&&get(g:,'pymode_python','')!=#'python')?'3': '')
" exe 'comm! -nargs=1 PythonI python'.s:py3.' <args>'
" exe 'comm! -nargs=1 PythonF py'.s:py3.'file <args>'
" exe "fun! IPythonPyeval(arg)\nreturn py".s:py3."eval (a:arg)\nendf"
" exe 'PythonI PY3 = '.(s:py3!=#'' ? 'True' : 'False')
