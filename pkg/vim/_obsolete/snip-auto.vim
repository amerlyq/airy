" DEPRECATED: USE 'kopischke/vim-stay' with 'konfekt/FastFold'
" Тут есть как сделать мануальный и автоматический фолдинг одновременно
"  http://vim.wikia.com/wiki/Folding
augroup MixedFolding
  autocmd!
  au BufReadPre * setl foldmethod=indent
  au BufWinEnter * if &fdm == 'indent' | setl fdm=manual | endif "| norm! zR
augroup END

"" Key-remaps

" BAD: breaks for <C-v>$ append-to-end
" Don't select eol spaces and '\n'. Instead use 'D' or 'DgJ'.
" xnoremap <unique> $  g_

" DEPRECATED: use 'vv' and plugins: vim-niceblock, vim-textobj-blockwise
" noremap <unique> ,v  <C-V>
" BAD: Swap v and CTRL-V was pitiful idea
