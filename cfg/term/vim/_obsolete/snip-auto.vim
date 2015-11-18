" DEPRECATED: USE 'kopischke/vim-stay'
" Open at last position
au MyAutoCmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \| exe "normal g'\"" | endif


" DEPRECATED: USE 'kopischke/vim-stay' with 'konfekt/FastFold'
" Тут есть как сделать мануальный и автоматический фолдинг одновременно
"  http://vim.wikia.com/wiki/Folding
augroup MixedFolding
  autocmd!
  au BufReadPre * setl foldmethod=indent
  au BufWinEnter * if &fdm == 'indent' | setl fdm=manual | endif "| norm! zR
augroup END
