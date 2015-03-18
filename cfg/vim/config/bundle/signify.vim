" using only git
let g:signify_vcs_list = [ 'git' ]
let g:signify_sign_change = '~'
let g:signify_sign_delete = '-'

noremap <unique> <leader>tg :<C-u>SignifyToggle \| redraw!<CR>
noremap <unique> <leader>tG :<C-u>SignifyToggleHighlight \| redraw!<CR>

nmap <unique> ]c <Plug>(signify-next-hunk)
nmap <unique> [c <Plug>(signify-prev-hunk)
" If those ]c will be busy, then signify automaps:
" nmap <leader>gj <plug>(signify-next-hunk)
" nmap <leader>gk <plug>(signify-prev-hunk)

omap <unique> ig <Plug>(signify-motion-inner-pending)
xmap <unique> ig <Plug>(signify-motion-inner-visual)
omap <unique> ag <Plug>(signify-motion-outer-pending)
xmap <unique> ag <Plug>(signify-motion-outer-visual)


" " highlight lines in Sy and vimdiff etc.)
"
" highlight DiffAdd           cterm=bold ctermbg=none ctermfg=119
" highlight DiffDelete        cterm=bold ctermbg=none ctermfg=167
" highlight DiffChange        cterm=bold ctermbg=none ctermfg=227
"
" " highlight signs in Sy
"
" highlight SignifySignAdd    cterm=bold ctermbg=237  ctermfg=119
" highlight SignifySignDelete cterm=bold ctermbg=237  ctermfg=167
" highlight SignifySignChange cterm=bold ctermbg=237  ctermfg=227

