nnoremap <Leader>th :setlocal hlsearch!<CR>
nnoremap <Leader>tl :setlocal list!<CR>
nnoremap <Leader>tp :setlocal spell!<CR>
nnoremap <Leader>tc :setlocal cursorcolumn!<CR>
nnoremap <Leader>tC :setlocal cursorline!<CR>

" Слева появится колонка шириной в 3 символа, обозначающая где какие фолдинги
" и какого уровня.  По ней можно будет кликать для сворачивания-разворачивания.
set foldenable foldcolumn=2
nnoremap <Leader>tz :call ToggleFolding()<CR>
function! ToggleFolding()
    if(&foldenable == 1)
        set nofoldenable
        set foldcolumn=0
    else
        set foldenable
        set foldcolumn=2
    endif
endfunc

" toggle between number and relativenumber
set number
nnoremap <Leader>tN :setlocal number!<CR>
nnoremap <Leader>tn :call ToggleNumber()<CR>
function! ToggleNumber()
    if(&relativenumber == 1)
        set norelativenumber
        set number
    else
        set relativenumber
    endif
endfunc

" Syntax highlighting
nnoremap <Leader>ts :call ToggleSyntax()<CR>
function! ToggleSyntax()
if g:syntax_on == 1
  syntax off
  let g:syntax_on = 0
else
  syntax on
  let g:syntax_on = 1
endif
endfunction

noremap <Leader>tx <Esc>:SyntasticToggleMode<CR>
"\| :SyntasticCheck<CR>
