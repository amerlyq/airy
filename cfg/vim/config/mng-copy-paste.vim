function! CountCopyLines(msg)
  let l = split(@+, '^.\{-}\zs\n')  " -- w/o,  '\n\zs' -- with
  let h = a:msg . len(l) . 'L> '
  let maxlen = min([ len(l[0]), &columns - len(h) - 13 ])
  echo h . substitute(l[0][0:l:maxlen], "\t", " ", 'g')
endfunction

nnoremap <C-y> :let @+=@" \| :call CountCopyLines('Push:')<CR>
vnoremap <C-y> :<C-U>call CountCopyLines('Push:')<CR>gv"+y
nnoremap <C-p> :let @"=@+ \| :call CountCopyLines('Pull:')    <CR>
vnoremap <C-p> :<C-U>call CountCopyLines('Pull:')<CR>gv"+P <CR>
" Swap registry
noremap  <M-c> :let @a=@" \| let @"=@+ \| let @+=@a \| reg "+<CR><CR>
"" Don't use paste in cmap as I use C-n C-p for navigation in command line
"cmap <F7> <C-\>eescape(getcmdline(), ' \')<CR> "setreg(''+'', getreg('':''))
cnoremap <C-y> <C-R>=setreg('+', getcmdline())<CR><C-H>


map ,y "+y
map ,p "+p
map ,P "+P
" Yank full line w/o newline and surrounded spaces
nnoremap ,Y mz^"+yg_`z

" Prevent Paste loosing the register source. Deleted available by "- reg
" http://stackoverflow.com/a/7797434/1147859
vnoremap p pgvy
vnoremap P Pgvy
" vnoremap P  "_dP
" vnoremap p  "_dP
noremap  zp "0p
noremap  zP "0P

" map <Leader>p :set paste<CR>o<esc>"*]p:set nopaste<cr>
