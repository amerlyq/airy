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

nnoremap <silent>  <Space>  :Limio i<CR>
vnoremap <silent>  <Space>  :<C-U>Limio I<CR>
nnoremap <silent> g<Space>  :Limio a<CR>
vnoremap <silent> g<Space>  :<C-U>Limio A<CR>
nnoremap <silent> ,<Space>  :Limio s<CR>
vnoremap <silent> ,<Space>  :<C-U>Limio S<CR>

" <S-Space> work only in gvim
