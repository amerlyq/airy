"set foldmethod=manual syntax  syntax defines folds
set foldlevelstart=99 " close folds below this depth, initially
"set foldopen=all

" Concealing
set concealcursor=cv " hide in command and visual modes.
" concealed text is completely hidden unless it has a custom replacement character defined.
set conceallevel=2

autocmd ColorScheme * highlight Folded ctermfg=yellow ctermbg=NonE
" :highlight FoldColumn guibg=darkgrey guifg=white
" set foldtext=getline(v:foldstart)

function! RefinedFoldText()
    let line = getline(v:foldstart)
    let sub = substitute(line, '/\*\|\*/\|{{{\d\=', '', 'g')
    return '' . v:foldlevel . ' >' . v:folddashes . sub
endfunction
set foldtext=RefinedFoldText()

" Тут есть как сделать мануальный и автоматический фолдинг одновременно
"  http://vim.wikia.com/wiki/Folding

