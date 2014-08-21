set backspace=indent,eol,start
" Or i<CR><Esc> for left-split

nnoremap K  a<CR><Esc>l
nnoremap gK d0o<Esc>p
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

" Ctrl-пробел дл€ автодополнени€
inoremap <C-space> <C-x><C-o>

" set tildeop   "allow moves for register change, like  ~w -- for word

" ¬ыбор формата концов строк (dos - , unix - , mac - ) -->
"set wcm=
"menu Encoding.FileFormat.unix :set fileformat=unix
"menu Encoding.FileFormat.dos :set fileformat=dos
"menu Encoding.FileFormat.mac :set fileformat=mac
"map :emenu Encoding.FileFormat.
" ¬ыбор формата концов строк (dos - , unix - , mac - ) <--

" Doxygen syntax highlighting
" manually: set syn=cpp.doxygen
" if very slow (on \c, \b ): set regexpengine=1
"let g:load_doxygen_syntax=1

