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
