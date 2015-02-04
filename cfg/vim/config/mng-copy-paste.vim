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
" To be able copy/paste regex snippets into vim/snippets/vim_regex.otl
nnoremap <C-/> :let @/=@+<CR>


map ,y "+y
map ,p "+p
map ,P "+P
" Yank full line w/o newline and surrounded spaces
nnoremap ,Y mz^"+yg_`z

" Get text to current
" TODO: Add ability to copy visual selection
function! LNf(...)
    let len =  a:0 >= 1 ? a:1 : " "
    let href=@% . ":" . line(".") . len
    exec 'let @+="' . href . '"'
    echo "REF: " . href
endfunction
command! -bar LN call LNf()
command! -bar LL call LNf("\n\t" . getline(".")) "split(getline('.'))
nnoremap \Y :<C-U>LN<CR>
nnoremap \t :<C-U>LL<CR>

function! CompileInDir(...)
  let run = a:0 >= 1  ?  a:1 . ' '  :  '!'
  " 'actualee ' . @% . ' || ' .
  exec l:run . 'abyss || { [ $? -eq 255 ] && abyss ' . @% . '}'
  " set makeprg=ruby\ -c\ %
endfunction

command! -bar -nargs=? CompilerInDir call CompileInDir(<args>)

" Prevent Paste loosing the register source. Deleted available by "- reg
" http://stackoverflow.com/a/7797434/1147859
vnoremap p pgvy
vnoremap P Pgvy
" vnoremap P  "_dP
" vnoremap p  "_dP
noremap  zp "0p
noremap  zP "0P

" map <Leader>p :set paste<CR>o<esc>"*]p:set nopaste<cr>
