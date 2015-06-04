" astyle for C#, C++, C and Java
" autopep8 for Python
" js-beautify for Javascript and JSON
" html-beautify for HTML
" css-beautify for CSS
" tidy for XHTML and XML


" let g:formatprg_<filetype>=/path/to/bin
" let g:formatprg_c=/bin/clang

let g:formatprg_cs = "astyle"
" let g:formatprg_args_cs = "--mode=cs --style=ansi -pcHs4"
let g:formatprg_args_expr_cs = '"--mode=cs --style=ansi -pcHs".&shiftwidth'

noremap <F3> :Autoformat<CR><CR>
