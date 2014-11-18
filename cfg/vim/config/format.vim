set autoindent       " automatically indent new lines
set formatoptions+=o " continue comment marker in new lines
set formatoptions+=n " recognize numbered lists

if v:version >= 704
    set formatoptions+=j " remove a comment leader when joining lines
endif

"Moving
set scrolloff=3   " context lines around cursor not hiding when scroll
set scrolljump=5  " minimum number of lines to scroll

set backspace=indent,eol,start

" Indenting
if has("autocmd")
    " make Python follow PEP8 ( http://www.python.org/dev/peps/pep-0008/ )
    autocmd FileType python
        \ set softtabstop=4 tabstop=4 shiftwidth=4 textwidth=79
    autocmd FileType make
        \ set tabstop=4 shiftwidth=4 softtabstop=0 noexpandtab
endif

set formatoptions+=l " don't auto-wrap line if it was longer before insert
"set textwidth=118    " hard-wrap long lines as you type them
set tabstop=4        " render TABs using this many spaces
set softtabstop=4    " ... this many spaces
set shiftwidth=4     " indentation amount for < and > commands
set expandtab        " insert spaces when TAB is pressed
set smarttab

" TRY: wrap only on \s chars
set linebreak
