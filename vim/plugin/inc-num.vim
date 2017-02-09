if &cp||exists('g:loaded_incnum')|finish|else|let g:loaded_incnum=1|endif
" SEE: http://vim.wikia.com/wiki/Making_a_list_of_numbers
" TODO: make <C-a> work on %V zone, increasing each number by 1

fun! s:asc()
  " CHECK: aren't it wrong -- resulting in 'a==0'?
  let a = line('.') - line("'<")
  let c = virtcol("'<")
  if a > 0
    execute 'normal! '.c.'|'.a."\<C-a>"
  endif
  normal `<
endf

" Replace column of identical numbers N by asceding sequence [N, N+dC]
xnoremap <unique> <Leader><C-a> :call s:asc()<CR>
