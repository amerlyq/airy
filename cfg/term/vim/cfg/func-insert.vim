" vim:tw=78:ts=2:norl:

" Insert characters
function! LimitedInput(mode) range
  if v:count1 < 2
    let str=nr2char(getchar()) "repeat(a:char, a:count)
  else
    let str=join(map(range(1,v:count1), 'nr2char(getchar())'),"")
  endif

  if a:mode == 's'
    exec 'normal! i'   .l:str
    exec 'normal! la'  .l:str
  elseif a:mode == 'S'
    exec 'normal! A'   .l:str
    exec 'normal! gvI' .l:str
  else
    exec 'normal! ' . a:mode . l:str
  endif
endfunction

command! -bar -nargs=1 Limio call LimitedInput(<q-args>)
" silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)

nnoremap <silent>  <Space>  :Limio i<CR>
vnoremap <silent>  <Space>  :<C-U>Limio I<CR>
nnoremap <silent> g<Space>  :Limio a<CR>
vnoremap <silent> g<Space>  :<C-U>Limio A<CR>
nnoremap <silent> ,<Space>  :Limio s<CR>
vnoremap <silent> ,<Space>  :<C-U>Limio S<CR>

" <S-Space> work only in gvim


" Built-in autocompletion, word, line
" inoremap <C-space> <C-x><C-o>
" inoremap <C-space> <C-x><C-l>

" Line split
nnoremap K   a<CR><Right><Esc>
nnoremap gK  i<CR><Right><Esc>
nnoremap <C-k> i<CR><Right><Esc>:m .-2<CR>
nnoremap gX  lxh


