let g:signify_vcs_list = ['git', 'hg']
let g:signify_sign_change = '~'
let g:signify_sign_delete = '-'
" let g:signify_update_on_focusgained = 1

noremap <unique> zS :<C-u>SignifyFold<CR>
noremap <unique> [Toggle]g :<C-u>SignifyToggleHighlight\|SignifyRefresh<CR>
noremap <unique> [Toggle]G :<C-u>SignifyToggle<CR>

nmap <silent><unique> ]c <Plug>(signify-next-hunk)
nmap <silent><unique> [c <Plug>(signify-prev-hunk)

xmap <silent><unique> aS <Plug>(signify-motion-outer-visual)
omap <silent><unique> aS <Plug>(signify-motion-outer-pending)
xmap <silent><unique> iS <Plug>(signify-motion-inner-visual)
omap <silent><unique> iS <Plug>(signify-motion-inner-pending)
