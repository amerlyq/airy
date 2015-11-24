tnoremap   <ESC><ESC>   <C-\><C-n>

" Share the histories
augroup MyAutoCmd
  au CursorHold * if exists(':rshada') | rshada | wshada | endif
augroup END


"" THINK how to unset env var from inside vim?
"" Use cursor shape feature
" let $NVIM_TUI_ENABLE_CURSOR_SHAPE = 1
"" Use true color feature
" let $NVIM_TUI_ENABLE_TRUE_COLOR = 1
