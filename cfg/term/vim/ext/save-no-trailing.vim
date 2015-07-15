" remove trailing spaces before saving text files
" http://vim.wikia.com/wiki/Remove_trailing_spaces

autocmd BufWritePre * :call StripTrailingWhitespace()

" function! StripTrailingWhitespace()
"   if !&binary && &filetype != 'diff' "&& &filetype != 'conf'
"     normal! mz
"     normal! Hmy
"     if &filetype == 'mail'
"       " preserve space after e-mail signature separator
"       %s/\(^--\)\@<!\s\+$//e
"     else
"       %s/\s\+$//e
"     endif
"     normal! 'yz<Enter>
"     normal! `z
"   endif
" endfunction

function ShowSpaces(...)
  let @/='\v(\s+$)|( +\ze\t)'
  let l:old=&hlsearch
  let &hlsearch = a:0 ? a:1 : !&hlsearch
  return l:old
endfunction

function TrimSpaces() range
  let oldhlsearch=ShowSpaces(1)
  " ///gec -- to highlight and ask if replace
  execute a:firstline.",".a:lastline."substitute ///ge"
  let &hlsearch=oldhlsearch
endfunction

command -bar -nargs=? ShowSpaces call ShowSpaces(<args>)
command -bar -nargs=0 -range=% TrimSpaces <line1>,<line2>call TrimSpaces()
" nnoremap <F12>     :ShowSpaces 1<CR>
" nnoremap <S-F12>   m`:TrimSpaces<CR>``
" vnoremap <S-F12>   :TrimSpaces<CR>

function! StripTrailingWhitespace()
  let l = line(".")
  let c = col(".")
  TrimSpaces
  call cursor(l, c)
endfunction
