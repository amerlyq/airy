"nmap <silent> ,s "=nr2char(getchar())<cr>P
function! LimitedInput(count) "char,
  if v:count < 2
    return nr2char(getchar()) "repeat(a:char, a:count)
  else
    return join(map(range(1,v:count1), 'nr2char(getchar())'),"")
  endif
endfunction
"Alt: noremap <Leader>a :<C-U>exec ("normal /" . nr2char(getchar()) . "\<lt>CR>") <CR>
nnoremap <silent> <Space>  :<C-U>exec "normal i".LimitedInput(v:count1)<CR>
nnoremap <silent> g<Space> :<C-U>exec "normal a".LimitedInput(v:count1)<CR>
" <S-Space> work only in gvim

" vim:tw=78:ts=2:norl:
