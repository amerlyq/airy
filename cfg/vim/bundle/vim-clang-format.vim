" H100%, S45%
" http://clang.llvm.org/docs/ClangFormatStyleOptions.html
"
" llvm, google, chromium, mozilla
let g:clang_format#code_style='google'

let g:clang_format#command = 'clang-format-3.5'

"" For config information, execute clang-format -dump-config command.
let g:clang_format#style_options = {
    \ "AccessModifierOffset" : -4,
    \ "AllowShortIfStatementsOnASingleLine" : "true",
    \ "AlwaysBreakTemplateDeclarations" : "true",
    \ "Standard" : "C++11",
    \ }
    " \ "BreakBeforeBraces" : "Stroustrup",

" let g:clang_format#extra_args

" automatically detects the style file like .clang-format or _clang-format and
" applies the style to formatting
" g:clang_format#detect_style_file


" let g:clang_format#auto_format = 1
" let g:clang_format#auto_format_on_insert_leave = 1
" " Map gq to use clang-format to format.
" let g:clang_format#auto_formatexpr = 1

"" map to <Leader>cf in C++ code
"" Format all
" autocmd FileType c,cpp,objc nnoremap <buffer><Leader>cf :<C-u>ClangFormat<CR>
" autocmd FileType c,cpp,objc vnoremap <buffer>gf :ClangFormat<CR>
" Only if you install 'vim-operator-user'
autocmd FileType c,cpp,objc map <buffer>\x <Plug>(operator-clang-format)
