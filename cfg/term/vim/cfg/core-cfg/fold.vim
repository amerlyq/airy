"{{{1 Fold/Conceal ============================
set foldenable
set foldcolumn=2        " fold levels ruler on left (clickable)
"set foldmethod=manual  " <expr|syntax|marker> -- syntax defines folds
set foldlevelstart=99   " close folds below this depth, initially
" set foldopen=all        " open on cursor touch, DISABLED: prevents 'za' fold
" if exists('*s:RefinedFoldText')
set foldtext=s:RefinedFoldText()  " ALT getline(v:foldstart)

set concealcursor=cv    " Concealing -- hide in command and visual modes.
set conceallevel=2      " Conceal all hidden beside having custom replacement


"{{{1 Mappings ============================
nnoremap <unique> <Leader>tz :let &foldmethod=(&fdm=='manual'?'syntax':
      \ &fdm=='syntax'?'marker': 'manual') \| set foldenable fdm?<CR>
nnoremap <unique> <Leader>tZ :let &fdc=(&fdc?0:2) \| set foldenable! fen?<CR>


"{{{1 Mixed/Folding ============================
" Тут есть как сделать мануальный и автоматический фолдинг одновременно
"  http://vim.wikia.com/wiki/Folding
augroup MixedFolding
    autocmd!
    au BufReadPre * setlocal foldmethod=indent
    au BufWinEnter * if &fdm == 'indent' | setlocal foldmethod=manual | endif
augroup END


fun! s:RefinedFoldText()
    let line = getline(v:foldstart)
    let sub = substitute(line, '/\*\|\*/\|{{{\d\=', '', 'g')
    return '' . v:foldlevel . ' >' . v:folddashes . sub
endfun
