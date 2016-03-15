" SEE: http://vim.wikia.com/wiki/Making_a_list_of_numbers
" TODO: make <C-a> work on %V zone, increasing each number by 1

function! s:asc()
  let a = line('.') - line("'<")
  let c = virtcol("'<")
  if a > 0
    execute 'normal! '.c.'|'.a."\<C-a>"
  endif
  normal `<
endfunction

" Replace column of identical numbers N by asceding sequence [N, N+dC]
xnoremap <unique> <Leader><C-a> :call s:asc()<CR>
