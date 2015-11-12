" Remove trailing spaces before saving text files
"   http://vim.wikia.com/wiki/Remove_trailing_spaces

"{{{1 CMDS ====================
let g:trailing_space = 1

command! -bar -nargs=0 TrailingSpaceOnSaveToggle
      \ let g:trailing_space = !g:trailing_space | echo g:trailing_space
command! -bar -nargs=? TrailingSpaceShow
      \ call s:TrailingSpaceShow(<args>)
command! -bar -nargs=0 -range=% TrailingSpaceStrip
      \ <line1>,<line2>call s:TrailingSpaceStrip()

" nnoremap <F12>     :ShowSpaces 1<CR>
" nnoremap <S-F12>   m`:TrimSpaces<CR>``
" vnoremap <S-F12>   :TrimSpaces<CR>


"{{{1 AUTO ====================
augroup TrailingSpace
  au!
  au BufWritePre * if g:trailing_space | call s:TrailingSpaceStrip() | endif
augroup END

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


"{{{1 IMPL ====================
fun! s:TrailingSpaceShow(...)
  let @/ = '\v(\s+$)|( +\ze\t)'
  let l:old = &hlsearch
  let &hlsearch = a:0 ? a:1 : !&hlsearch
  return l:old
endfunction

fun! s:TrailingSpaceTrim() range
  let l:oldhlsearch=s:TrailingSpaceShow(1)
  " ///gec -- to highlight and ask if replace
  execute a:firstline.",".a:lastline."substitute ///ge"
  let &hlsearch=l:oldhlsearch
endfunction

fun! s:TrailingSpaceStrip()
  let [l,c] = [line("."), col(".")]
  call s:TrailingSpaceTrim()
  call cursor(l, c)
endf
