" In Windows, can't find exe, when $PATH isn't contained $VIM.
if $PATH !~? '\(^\|;\)' . escape($VIM, '\\') . '\(;\|$\)'
  let $PATH = $VIM . ';' . $PATH
endif

" Use bash.
"set shell=bash.exe
"set shellcmdflag=-c
"set shellpipe=2>&1\|\ tee
"set shellredir=>%s\ 2>&1
"set shellxquote=\"

if has('vim_starting')
  " Augment Windows Platform
  set shellslash  " Exchange path separator.
  set lines=32
  set columns=112
  let &runtimepath = join([
        \ expand('~/.vim'),
        \ expand('$VIM/runtime'),
        \ expand('~/.vim/after')], ',')
  " Fix the path of vimrc and gvimrc for Windows
  let $MYVIMRC=$VIMHOME . '/vimrc'
  let $MYGVIMRC=$VIMHOME . '/gvimrc'
  language message en_US.UTF-8
  cd d:\
endif
