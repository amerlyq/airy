nmap <Leader>h <Plug>(quickhl-manual-this)
xmap <Leader>h <Plug>(quickhl-manual-this)

nmap <Leader>H <Plug>(quickhl-manual-toggle)
xmap <Leader>H <Plug>(quickhl-manual-toggle)

nmap g<Leader>h <Plug>(quickhl-cword-toggle)

" OR: nmap g<Leader>h <Plug>(quickhl-manual-reset)
nmap <Leader><C-l> <Plug>(quickhl-manual-reset)
xmap <Leader><C-l> <Plug>(quickhl-manual-reset)


"" Disabled: unusable on big tag base (like kernels)
" nmap g<Leader>] <Plug>(quickhl-tag-toggle)
"" Disabled: Collide with sideways.vim
" map gs <Plug>(operator-quickhl-manual-this-motion)


" let g:quickhl_manual_colors = [
"     \ "gui=bold ctermfg=16  ctermbg=153 guifg=#ffffff guibg=#0a7383",
"     \ "gui=bold ctermfg=7   ctermbg=1   guibg=#a07040 guifg=#ffffff",
"     \ "gui=bold ctermfg=7   ctermbg=2   guibg=#4070a0 guifg=#ffffff",
"     \ "gui=bold ctermfg=7   ctermbg=3   guibg=#40a070 guifg=#ffffff",
"     \ ]

