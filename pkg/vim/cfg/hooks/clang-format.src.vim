" SEE:(H100%, S45%) http://clang.llvm.org/docs/ClangFormatStyleOptions.html

" let g:clang_format#auto_format = 1
" let g:clang_format#auto_format_on_insert_leave = 1
let g:clang_format#code_style='llvm'  " llvm, google, chromium, mozilla
let g:clang_format#auto_formatexpr = 1

" OR: :<C-u>ClangFormat<CR>
au MyAutoCmd FileType c,cpp,objc nmap <buffer> gQ <Plug>(operator-clang-format)
au MyAutoCmd FileType c,cpp,objc xmap <buffer> gQ <Plug>(operator-clang-format)

" NOTE: For config information, exec: $ clang-format -dump-config
let g:clang_format#style_options = {
    \ "AccessModifierOffset" : -4,
    \ "AllowShortIfStatementsOnASingleLine" : "true",
    \ "AlwaysBreakTemplateDeclarations" : "true",
    \ "Standard" : "C++11",
    \ }
    " \ "BreakBeforeBraces" : "Stroustrup",
