"{{{1 Clipboard ============================
" TRY use copy-always -- and keep yank-history by copyq
" if has('unnamedplus')  " On neovim -- always false?
"   set clipboard& clipboard+=unnamedplus
" else
"   set clipboard& clipboard+=unnamed
" endif

set clipboard=unnamedplus
" set clipboard=unnamedplus,unnamed
