"{{{1 Clipboard ============================
" TRY use copy-always -- and keep yank-history by copyq

if exists($DISPLAY) && has('clipboard')
  " set clipboard=unnamedplus,unnamed
  if v:version > 703 || (v:version == 703 && has('patch74'))
    set clipboard=unnamedplus
  else
    set clipboard=unnamed
  endif
endif
