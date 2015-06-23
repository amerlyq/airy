" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1
if !neobundle#tap('rainbow') | finish | endif

let g:rainbow_active = 1

let g:rainbow_conf = {
  \ 'guifgs': ['royalblue3', 'darkorange3', 'seagreen3', 'firebrick'],
  \ 'ctermfgs': ['gray', 'lightcyan', 'lightyellow', 'lightblue', 'lightmagenta'],
  \ 'operators': '_,_',
  \ 'parentheses': ['start=/(/ end=/)/ fold', 'start=/\[/ end=/\]/ fold', 'start=/{/ end=/}/ fold'],
  \ 'separately': {
  \   '*': {},
  \   'c': { 'ctermfgs': [
  \     'gray', 'gray', 'lightblue', 'lightyellow', 'lightcyan', 'lightmagenta'
  \   ] },
  \   'cmake': 0,
  \   'css': 0,
  \   'html': {
  \     'parentheses': ['start=/\v\<((area|base|br|col|embed|hr|img|input|keygen|link|menuitem|meta|param|source|track|wbr)[ >])@!\z([-_:a-zA-Z0-9]+)(\s+[-_:a-zA-Z0-9]+(\=("[^"]*"|'."'".'[^'."'".']*'."'".'|[^ '."'".'"><=`]*))?)*\>/ end=#</\z1># fold'],
  \   },
  \   'lisp': { 'guifgs': [
  \     'royalblue3', 'darkorange3', 'seagreen3', 'firebrick', 'darkorchid3'
  \   ] },
  \    'sh': { 'parentheses': ['start=/(/ end=/)/', 'start=/{/ end=/}/'] },
  \   'tex': { 'parentheses': ['start=/(/ end=/)/', 'start=/\[/ end=/\]/'] },
  \   'vim': { 'parentheses': [
  \     'start=/(/ end=/)/', 'start=/\[/ end=/\]/', 'start=/{/ end=/}/ fold',
  \     'start=/(/ end=/)/ containedin=vimFuncBody',
  \     'start=/\[/ end=/\]/ containedin=vimFuncBody',
  \     'start=/{/ end=/}/ fold containedin=vimFuncBody'
  \   ] },
  \   'votl': 0,
  \   'zsh': { 'parentheses': ['start=/(/ end=/)/', 'start=/{/ end=/}/'] },
  \ }
  \}
