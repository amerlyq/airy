nnoremap <Leader>th :setlocal hlsearch!<CR>
nnoremap <Leader>tl :setlocal list!<CR>
nnoremap <Leader>tn :setlocal number!<CR>
nnoremap <Leader>tN :setlocal relativenumber!<CR>
nnoremap <Leader>tp :setlocal spell!<CR>
nnoremap <Leader>tz :setlocal foldenable!<CR>
nnoremap <Leader>tc :setlocal cursorcolumn!<CR>
nnoremap <Leader>tC :setlocal cursorline!<CR>

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
