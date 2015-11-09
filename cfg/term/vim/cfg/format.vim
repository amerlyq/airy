set autoindent       " automatically indent new lines
set cindent          " instead of 'smartindent' to not move '#' to right
set formatoptions+=o " continue comment marker in new lines
set formatoptions+=n " recognize numbered lists
set backspace=indent,eol,start
set commentstring=#\ %s  " Use sh-style comments by default instead of c-style

if v:version >= 704
    set formatoptions+=j " remove a comment leader when joining lines
endif

"Moving
set scrolloff=3   " context lines around cursor not hiding when scroll
set scrolljump=5  " minimum number of lines to scroll

set formatoptions+=l " don't auto-wrap line if it was longer before insert
"set textwidth=118    " hard-wrap long lines as you type them


" TRY: wrap only on \s chars
set linebreak
" Mitigate issue with auto-removing trainling whitespaces in wrapped file
" set showbreak=>\ \ \
" No more esc-insert mess when unindented typing wierd characters
set nodigraph
" Move by arrow keys on previous/next line around ends of line in command mode
set whichwrap=<,>

" set tildeop   "allow moves for register change, like  ~w -- for word

" Выбор формата концов строк (dos - , unix - , mac - ) -->
"set wcm=
"menu Encoding.FileFormat.unix :set fileformat=unix
"menu Encoding.FileFormat.dos :set fileformat=dos
"menu Encoding.FileFormat.mac :set fileformat=mac
"map :emenu Encoding.FileFormat.
" Выбор формата концов строк (dos - , unix - , mac - ) <--

