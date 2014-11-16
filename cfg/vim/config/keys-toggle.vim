nnoremap <Leader>th :setlocal hlsearch!<CR>
nnoremap <Leader>tl :setlocal list!<CR>
nnoremap <Leader>tp :setlocal spell!<CR>
nnoremap <Leader>tz :setlocal foldenable!<CR>
nnoremap <Leader>tc :setlocal cursorcolumn!<CR>
nnoremap <Leader>tC :setlocal cursorline!<CR>

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
