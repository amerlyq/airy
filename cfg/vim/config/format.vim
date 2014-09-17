set autoindent       " automatically indent new lines
set formatoptions+=o " continue comment marker in new lines
set formatoptions+=n " recognize numbered lists

if v:version >= 704
    set formatoptions+=j " remove a comment leader when joining lines
endif

set formatoptions+=l " don't wrap line automatically if it was longer before insert
"set textwidth=118    " hard-wrap long lines as you type them
set tabstop=4        " render TABs using this many spaces
set expandtab        " insert spaces when TAB is pressed
set softtabstop=4    " ... this many spaces
set shiftwidth=4     " indentation amount for < and > commands

"Moving
set scrolloff=3   " context lines around cursor not hiding when scroll
set scrolljump=5  " minimum number of lines to scroll

set backspace=indent,eol,start
