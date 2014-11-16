" Ctrl-пробел для автодополнения
inoremap <C-space> <C-x><C-o>

" Change Working Directory to that of the current file
cmap <Leader>cwd lcd %:p:h

" set tildeop   "allow moves for register change, like  ~w -- for word

" Выбор формата концов строк (dos - , unix - , mac - ) -->
"set wcm=
"menu Encoding.FileFormat.unix :set fileformat=unix
"menu Encoding.FileFormat.dos :set fileformat=dos
"menu Encoding.FileFormat.mac :set fileformat=mac
"map :emenu Encoding.FileFormat.
" Выбор формата концов строк (dos - , unix - , mac - ) <--

