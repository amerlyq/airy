" <S-Space> work only in gvim, but <C-Space> -- everywhere?

nnoremap <unique><silent> [Space]<Space>  i<Space><Esc>
vnoremap <unique><silent> [Space]<Space>  c<Space><C-r>"<Space><Esc>

nnoremap <unique><silent> <Leader><Space> a<Space><Left><Left><Space><Esc>
" xmap <unique><silent> [Space]<Space>  [Quote]a<Space>

nnoremap <unique><silent> [Space]i  :<C-u>Limio i<CR>
xnoremap <unique><silent> [Space]i  :<C-u>Limio I<CR>

nnoremap <unique><silent> [Space]a  :Limio a<CR>
xnoremap <unique><silent> [Space]a  :<C-u>Limio A<CR>

nnoremap <unique><silent> [Space]s  :Limio s<CR>
xnoremap <unique><silent> [Space]s  :<C-u>Limio S<CR>


command! -bar -nargs=1 Limio call LimitedInput(<q-args>)
" silent! call repeat#set("\<Plug>MyWonderfulMap", v:count)


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
