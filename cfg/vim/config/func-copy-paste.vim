" show the command history (q:)
" Remap line-up and move-up
" on visual area it must copy instantly! and only in @+
function! CountCopyLines(msg)
    let l = split(@+, '^.\{-}\zs\n')  " -- w/o,  '\n\zs' -- with
    let h = a:msg . len(l) . 'L> '
    let maxlen = min([ len(l[0]), &columns - len(h) - 2 ])
    echo h . substitute(l[0][0:maxlen], "\t", " ", 'g')
endfunction

nnoremap <C-y> :let @+=@" \| :call CountCopyLines('Push:')<CR>
cnoremap <C-y> :call setreg('+', getreg(':')) \| :call CountCopyLines('Push:')<CR><CR>
vnoremap <C-y> "+y \| :call CountCopyLines('Push:')<CR>
noremap  <C-p> :let @"=@+ \| :call CountCopyLines('Pull:') <CR>
" Swap registry
noremap  <M-c> :let @a=@" \| let @"=@+ \| let @+=@a \| reg "+<CR><CR>

noremap  zp "0p
noremap  zP "0P


