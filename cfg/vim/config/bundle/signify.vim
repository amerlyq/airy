" using only git
let g:signify_vcs_list = [ 'git' ]
let g:signify_sign_change = '~'
let g:signify_sign_delete = '-'

nmap <leader>tg <plug>(signify-toggle)
nmap <leader>tG <plug>(signify-toggle-highlight)

nmap ]c <plug>(signify-next-hunk)
nmap [c <plug>(signify-prev-hunk)
" If those ]c will be busy, then signify automaps:
" nmap <leader>gj <plug>(signify-next-hunk)
" nmap <leader>gk <plug>(signify-prev-hunk)


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

