" normal p is ':pu'

" show the command history (q:)
" Remap line-up and move-up
" on visual area it must copy instantly! and only in @+
function! CountCopyLines(msg)
    let l = split(@+, '^.\{-}\zs\n')  " -- w/o,  '\n\zs' -- with
    let h = a:msg . len(l) . 'L> '
    let maxlen = min([ len(l[0]), &columns - len(h) - 13 ])
    echo h . substitute(l[0][0:l:maxlen], "\t", " ", 'g')
endfunction

nnoremap <C-y> :let @+=@" \| :call CountCopyLines('Push:')<CR>
vnoremap <C-y> "+y \| :call CountCopyLines('Push:')<CR>
nnoremap <C-p> :let @"=@+ \| :call CountCopyLines('Pull:') <CR>
vnoremap <C-p> :call CountCopyLines('Pull:') \| normal "_d"+P <CR>

nnoremap ,y :let @+=@" \| :call CountCopyLines('Push:')<CR>
vnoremap ,y "+y \| :call CountCopyLines('Push:')<CR>
map ,p :<C-u>call CountCopyLines('Pull:') \| normal "+p<CR>
map ,P :<C-u>call CountCopyLines('Pull:') \| normal "+P<CR>
" vnoremap ,p :call CountCopyLines('Pull:') \| normal "_d"+P <CR>

" cnoremap <C-y> :<C-U>call setreg(''+'', getreg('':'')) \| call CountCopyLines(''Push:'')<CR><CR>
"" Don't use as I use C-n C-p for navigation in command line
" cnoremap <C-p> <C-U>exec 'call setreg('':'', getreg('':'') . getreg(''+'')) \| call CountCopyLines(''Pull:'')<CR>'<CR>


" Swap registry
noremap  <M-c> :let @a=@" \| let @"=@+ \| let @+=@a \| reg "+<CR><CR>

" Try it {{{
" nnoremap p "+p
" map <Leader>p :set paste<CR>o<esc>"*]p:set nopaste<cr>
" Prevent Paste loosing the register source:
" http://stackoverflow.com/a/7797434/1147859
xnoremap p pgvy
xnoremap P Pgvy
" }}}

noremap  zp "0p
noremap  zP "0P
vnoremap P  "_dP
vnoremap p  "_dP

" See: http://vim.wikia.com/wiki/Copy_search_matches
function! CopyMatches(reg)
  let hits = []
  %s//\=len(add(hits, submatch(0))) ? submatch(0) : ''/ge
  let reg = empty(a:reg) ? '+' : a:reg
  execute 'let @'.reg.' = join(hits, "\n") . "\n"'
endfunction
command! -register CopyMatches call CopyMatches(<q-reg>)
" Usage:
" :let @a = ''
" :bufdo CopyMatches A
