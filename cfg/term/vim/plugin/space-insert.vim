if &cp||exists('g:loaded_ispace')|finish|else|let g:loaded_ispace=1|endif
" <S-Space> work only in gvim, but <C-Space> -- everywhere?

nnoremap <unique><silent> [Space]<Space>  i<Space><Esc>
xnoremap <unique><silent> [Space]<Space>  c<Space><C-r>"<Space><Esc>

" ALT: use 'q<Space> from 'rhysd/vim-operator-surround'
nnoremap <unique><silent> <Leader><Space>  a<Space><Left><Left><Space><Esc>
xmap     <unique><silent> <Leader><Space>  [Quote]a<Space>

" BAD:FIXME: don't query for inserted char on repeat
"   http://vimcasts.org/episodes/creating-repeatable-mappings-with-repeat-vim/
nnoremap <silent> <Plug>(limio-i)  :<C-u>Limio i<Bar>call repeat#set("\<Plug>(limio-i)")<CR>
xnoremap <silent> <Plug>(limio-I)  :<C-u>Limio I<Bar>call repeat#set("\<Plug>(limio-I)")<CR>
nnoremap <silent> <Plug>(limio-a)  :Limio a<Bar>call repeat#set("\<Plug>(limio-a)")<CR>
xnoremap <silent> <Plug>(limio-A)  :<C-u>Limio A<Bar>call repeat#set("\<Plug>(limio-A)")<CR>
nnoremap <silent> <Plug>(limio-s)  :Limio s<Bar>call repeat#set("\<Plug>(limio-s)")<CR>
xnoremap <silent> <Plug>(limio-S)  :<C-u>Limio S<Bar>call repeat#set("\<Plug>(limio-S)")<CR>

nmap <unique><silent>  [Space]i  <Plug>(limio-i)
xmap <unique><silent>  [Space]i  <Plug>(limio-I)
nmap <unique><silent>  [Space]a  <Plug>(limio-a)
xmap <unique><silent>  [Space]a  <Plug>(limio-A)
nmap <unique><silent>  [Space]s  <Plug>(limio-s)
xmap <unique><silent>  [Space]s  <Plug>(limio-S)

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
