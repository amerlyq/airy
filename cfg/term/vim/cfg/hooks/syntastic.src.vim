" suppress 'no such file' error when browsing
let g:syntastic_check_on_open=0

" use the :sign interface to mark syntax errors.
let g:syntastic_enable_signs=1
" what the syntastic |:sign| text contains.
let g:syntastic_error_symbol='✗'
let g:syntastic_warning_symbol='⚠'
" the error window will be automatically closed when no errors are detected,
" but not opened automatically.
let g:syntastic_auto_loc_list=1
" let g:syntastic_always_populate_loc_list=1

" files that syntastic should neither check, nor include in error lists.
" let g:syntastic_ignore_files=['\m^/usr/include/', '\m\c\*\.h$']
" let g:syntastic_quiet_messages = { "file":  ['\m^/usr/include/', '\m\c\.h$'] }


let g:syntastic_c_compiler = 'gcc'
let g:syntastic_c_check_header = 0
let g:syntastic_c_include_dirs = [ 'inc', 'include', '../inc', '../include',  '../../include', '../../common/inc' ]
" let g:syntastic_c_compiler_options = '-Wall '

" let g:syntastic_c_compiler_options = '-std=c89 -Wall -Wdeclaration-after-statement -Werror -Wno-unused-variable -Wno-unused-but-set-variable'
" NOTE: Extracted from source. Hope this will suppress irritating 'not found'
let g:syntastic_c_remove_include_errors = 1
let g:syntastic_c_no_include_search = 1
let g:syntastic_c_config_file = '.sirrc'

" map non-standard filetypes to standard ones.
let g:syntastic_filetype_map = { 'latex': 'tex',
                               \ 'gentoo-metadata': 'xml' }


" let g:syntastic_c_cflags = '-I/usr/src/linux-headers-$(uname -r)/include'

let g:syntastic_cpp_compiler = 'g++'
let g:syntastic_cpp_compiler_options = '-std=c++11 '
let g:syntastic_cpp_check_header = 0
let g:syntastic_cpp_include_dirs = [ 'inc', 'include', '../inc', '../include', '../../include' ]
let g:syntastic_cpp_remove_include_errors = 1
let g:syntastic_cpp_no_include_search = 1
let g:syntastic_cpp_config_file = '.sirrc' "'.clang_complete'


" '-ansi -DMACRO_NAME'

" Syntastic uses the location list (a window-local variant of the quickfix
" list), so a :lclose will close it, but keep the other buffers.

" the initial height can be configured:
let g:syntastic_loc_list_height=5

""" Python """
let g:syntastic_python_checkers = []
let g:syntastic_enable_perl_checker = 1

""" Haskell """
let g:syntastic_haskell_checkers = ['hlint']  " 'hdevtools', 'ghc-mod'
