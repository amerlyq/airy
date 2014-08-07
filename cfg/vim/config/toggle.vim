nnoremap <Leader>th :setlocal hlsearch!<cr>
nnoremap <Leader>tl :setlocal list!<cr>
nnoremap <Leader>tn :setlocal number!<cr>
nnoremap <Leader>tN :setlocal relativenumber!<cr>
nnoremap <Leader>tp :setlocal spell!<cr>
nnoremap <Leader>tz :setlocal foldenable!<cr>
nnoremap <Leader>tc :setlocal cursorcolumn!<cr>
nnoremap <Leader>tC :setlocal cursorline!<cr>

nnoremap <Leader>ts :call ToggleSyntax()<cr>
function! ToggleSyntax()
if g:syntaxon == 1
  syntax off
  let g:syntaxon = 0
else
  syntax on
  let g:syntaxon = 1
endif
endfunction
