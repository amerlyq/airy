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

" nnoremap <unique><silent> [Space]<Space>  i<Space><Esc>
" xmap <unique><silent> [Space]<Space>  [Quote]a<Space>
nnoremap <unique><silent> [Space]i  :<C-U>Limio i<CR>
xnoremap <unique><silent> [Space]i  :<C-U>Limio I<CR>
nnoremap <unique><silent> [Space]a  :Limio a<CR>
xnoremap <unique><silent> [Space]a  :<C-U>Limio A<CR>
nnoremap <unique><silent> [Space]s  :Limio s<CR>
xnoremap <unique><silent> [Space]s  :<C-U>Limio S<CR>

" <S-Space> work only in gvim


" Built-in autocompletion, word, line
" inoremap <C-space> <C-x><C-o>
" inoremap <C-space> <C-x><C-l>

" Line split
nnoremap K   a<CR><Right><Esc>
xnoremap K   c<CR><Esc>
nnoremap gK  i<CR><Right><Esc>
nnoremap <C-k> i<CR><Right><Esc>:m .-2<CR>
nnoremap gX  lxh

" DEV: use <Space> as <Leader-2>
" space,space -- insert space
" space,p/P -- insert space, then paste
