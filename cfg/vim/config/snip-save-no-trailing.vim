" remove trailing spaces before saving text files
" http://vim.wikia.com/wiki/Remove_trailing_spaces

autocmd BufWritePre * :call StripTrailingWhitespace()

function! StripTrailingWhitespace()
  if !&binary && &filetype != 'diff' "&& &filetype != 'conf'
    normal! mz
    normal! Hmy
    if &filetype == 'mail'
      " preserve space after e-mail signature separator
      %s/\(^--\)\@<!\s\+$//e
    else
      %s/\s\+$//e
    endif
    normal! 'yz<Enter>
    normal! `z
  endif
endfunction

