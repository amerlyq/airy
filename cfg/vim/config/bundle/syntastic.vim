" use the :sign interface to mark syntax errors.
let g:syntastic_enable_signs=1
" what the syntastic |:sign| text contains.
let g:syntastic_error_symbol='✗'
let g:syntastic_warning_symbol='⚠'
" the error window will be automatically closed when no errors are detected,
" but not opened automatically.
let g:syntastic_auto_loc_list=1
" files that syntastic should neither check, nor include in error lists.
let g:syntastic_ignore_files=['^/usr/include/']
" map non-standard filetypes to standard ones.
let g:syntastic_filetype_map = { 'latex': 'tex',
                               \ 'gentoo-metadata': 'xml' }
let g:syntastic_cpp_compiler = 'clang++'
let g:syntastic_cpp_config_file = '.clang_complete'

noremap <Leader>tx <Esc>:SyntasticToggleMode<CR>
"\| :SyntasticCheck<CR>

