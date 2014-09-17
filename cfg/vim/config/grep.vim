if executable('ack')
    set grepprg=ack\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow\ $*
    set grepformat=%f:%l:%c:%m
endif

if executable('ag')
    set grepprg=ag\ --nogroup\ --column\ --smart-case\ --nocolor\ --follow
    set grepformat=%f:%l:%c:%m
endif

" Doxygen syntax highlighting. Very slow on \c, \b. So set those:
set regexpengine=1          " Do not use NFA because doxygen style will be slow
let g:load_doxygen_syntax=1 " Load doxygen syntax by default
" manually: set syn=cpp.doxygen

" Ctags {
" set tags=./tags;/,~/.vimtags
" Make tags placed in .git/tags file available in all levels of a repository
" let gitroot = substitute(system('git rev-parse --show-toplevel'), '[\n\r]', '', 'g')
" if gitroot != ''
"     let &tags = &tags . ',' . gitroot . '/.git/tags'
" endif
