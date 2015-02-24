" NOTE: cmap: C-R,C-G inserts current file name
":s;|;\\^M|;g  | split pipe on multiline
"To comment (instead of C-V): select by S-V, then type : s/^/#
" list all occurrences of word under cursor in current buffer: [I

""" Helpers
function! CountCopiedLines(msg)
  let l = split(@+, '^.\{-}\zs\n')  " -- w/o,  '\n\zs' -- with
  let h = a:msg . len(l) . 'L> '
  let maxlen = min([ len(l[0]), &columns - len(h) - 13 ])
  echo h . substitute(l[0][0:l:maxlen], "\t", " ", 'g')
endfunction

function! GetVisualSelection()
  " Why is this not a built-in Vim script function?!
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return lines
endfunction

function! GetCurrentLine(...)
    let len =  a:0 >= 1 ? a:1 : " "
    let href=@% . ":" . line(".") . len
    let @+=href
    call CountCopiedLines("REF: ")
endfunction


" Be consistent with C and D which reach the end of line
nnoremap Y y$
" Yank full line w/o newline and surrounded spaces
nnoremap ,Y mz^"+yg_`z
" Prevent Paste loosing the register source. Deleted available by "- reg.
"   http://stackoverflow.com/a/7797434/1147859
vnoremap p pgvy
vnoremap P Pgvy
noremap  zp "0p
noremap  zP "0P


map <leader>y "+y
map <leader>p "+p
map <leader>P "+P

" Duplicate unnamed and copy registers
nnoremap <C-y> :let @+=@" \| :call CountCopiedLines('Push:')<CR>
vnoremap <C-y> :<C-U>call CountCopiedLines('Push:')<CR>gv"+y
nnoremap <C-p> :let @"=@+ \| :call CountCopiedLines('Pull:')<CR>
vnoremap <C-p> :<C-U>call CountCopiedLines('Pull:')<CR>gv"+P<CR>
" Swap registry
noremap  <M-c> :let @a=@" \| let @"=@+ \| let @+=@a \| reg "+<CR><CR>

" Copy from prompt ':' or '/'. Paste in them by <C-R>+ or <C-R>".
cnoremap <C-y> <C-R>=setreg('+', getcmdline())<CR><C-H>
" To be able copy/paste regex snippets into vim/snippets/vim_regex.otl
nnoremap <leader>/ :let @/=@+<CR> \| :call CountCopiedLines('Search:')
"" Don't use paste in cmap as I use C-n C-p for navigation in command line
"cmap <F7> <C-\>eescape(getcmdline(), ' \')<CR> "setreg(''+'', getreg('':''))


let s:leader = g:mapleader
let mapleader = "\\"
  nnoremap <leader>Y :<C-U>call LNf()<CR>
  nnoremap <leader>t :<C-U>call LNf("\n\t".getline("."))<CR>
  vnoremap <leader>t <Esc>:call LNf("\n\t".join(GetVisualSelection(), "\n\t"))<CR>
let mapleader = s:leader

