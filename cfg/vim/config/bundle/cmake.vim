let g:cmake_build_type = "Debug"
let g:cmake_build_dirs = [ "build" ]
let g:cmake_cxx_compiler = 'g++'
let g:cmake_c_compiler = 'gcc'

" Determines whether or not the 'makeprg' value in Vim will be set to a tweaked
" 'make' where it builds using the files in your specified build directory.
let g:cmake_set_makeprg = 1

let g:cmake_inject_flags = { 'syntastic': 1, 'ycm':0 }
" let g:cmake_install_prefix = "$HOME/.local"
