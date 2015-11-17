"{{{1 Clipboard ============================
" TRY use copy-always -- and keep yank-history by copyq

" if has('unnamedplus')  " On neovim -- always false?
if has('clipboard')
  set clipboard=unnamedplus
" set clipboard=unnamedplus,unnamed
endif
