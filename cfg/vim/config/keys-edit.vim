set backspace=indent,eol,start

"d0o<Esc>p
nnoremap K  a<CR><Right><Esc>
nnoremap gK i<CR><Right><Esc>

" Jump to a new line in insert mode
inoremap <M-CR> <Esc>o
"noremap <Leader>d "_d

"" по звездочке не прыгать на следующее найденное, а просто подсветить
" don't works cause of plugin vim-indexed-search remapping
"nnoremap * *N
vnoremap * y :execute ":let @/=@\""<CR> :execute "set hlsearch"<CR>

"nmap <silent> ,s "=nr2char(getchar())<cr>P
function! RepeatChar(char, count)
  return repeat(a:char, a:count)
endfunction
"Alt: noremap <Leader>a :<C-U>exec ("normal /" . nr2char(getchar()) . "\<lt>CR>") <CR>
nnoremap <silent> <Space> :<C-U>exec "normal i".RepeatChar(nr2char(getchar()), v:count1)<CR>
nnoremap <silent> g<Space> :<C-U>exec "normal a".RepeatChar(nr2char(getchar()), v:count1)<CR>
" <S-Space> work only in gvim

" Ctrl-пробел для автодополнения
inoremap <C-space> <C-x><C-o>

" set tildeop   "allow moves for register change, like  ~w -- for word

" Выбор формата концов строк (dos - , unix - , mac - ) -->
"set wcm=
"menu Encoding.FileFormat.unix :set fileformat=unix
"menu Encoding.FileFormat.dos :set fileformat=dos
"menu Encoding.FileFormat.mac :set fileformat=mac
"map :emenu Encoding.FileFormat.
" Выбор формата концов строк (dos - , unix - , mac - ) <--

" Doxygen syntax highlighting. Very slow on \c, \b. So set those:
set regexpengine=1          " Do not use NFA because doxygen style will be slow
let g:load_doxygen_syntax=1 " Load doxygen syntax by default
" manually: set syn=cpp.doxygen
