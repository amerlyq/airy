"{{{1 Clipboard ============================
" TRY use copy-always -- and keep yank-history by copyq
if has('unnamedplus')
  set clipboard& clipboard+=unnamedplus
else
  set clipboard& clipboard+=unnamed
endif


