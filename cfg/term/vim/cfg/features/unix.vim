if exists('$WINDIR') || !executable('zsh')
  " Cygwin.
  set shell=bash
endif
" Set path.
" let $PATH = expand('~/bin').':/usr/local/bin/:'.$PATH
