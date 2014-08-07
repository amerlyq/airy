set backspace=indent,eol,start
" Or i<CR><Esc> for left-split

nnoremap K  a<CR><Esc>l
nnoremap gK d0o<Esc>p
"noremap <Leader>d "_d

"noremap <leader>ct <Esc>:retab<CR>, :retab!
noremap <leader>ct :s:^\t\+:\=repeat(" ", len(submatch(0))*' . &ts . ')<CR>
noremap <leader>cT :s:^\( \{'.&ts.'\}\)\+:\=repeat("\t", len(submatch(0))/' . &ts . ')<CR>
noremap <leader>ce :<C-U>%s:^\s*$\n::<CR>
noremap <leader>cc :<C-U>%s:\<<C-R><C-W>\>:<C-R><C-W>:g<Left><Left>
noremap <leader>cC :s:\<<C-R><C-W>\>:<C-R><C-W>:g<Left><Left>
noremap <leader>cy <Esc>:%s:\<<C-R><C-W>\>:<C-R>0:g<Left><Left>
":s;|;\\^M|;g  | split pipe on multiline

nnoremap <leader>jt <Esc>:%!python -m json.tool<CR><Esc>:set filetype=json<CR>

"nmap <silent> ,s "=nr2char(getchar())<cr>P
function! RepeatChar(char, count)
  return repeat(a:char, a:count)
endfunction
"Alt: noremap <Leader>a :<C-U>exec ("normal /" . nr2char(getchar()) . "\<lt>CR>") <CR>
nnoremap <silent> <Space> :<C-U>exec "normal i".RepeatChar(nr2char(getchar()), v:count1)<CR>
nnoremap <silent> g<Space> :<C-U>exec "normal a".RepeatChar(nr2char(getchar()), v:count1)<CR>
" <S-Space> work only in gvim


"nnoremap <C-=> "+P
"nnoremap <C-+> "+y

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
let g:load_doxygen_syntax=1

