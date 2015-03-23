" vim:ts=2:sw=2:sts=2
" NOTE: cmap: C-R,C-G inserts current file name
":s;|;\\^M|;g  | split pipe on multiline
"To comment (instead of C-V): select by S-V, then type : s/^/#
" list all occurrences of word under cursor in current buffer: [I
" SEE: http://www.ibm.com/developerworks/library/l-vim-script-2/

""" Helpers
function! CountLinesInRegister(reg, msg)
  let l = split(getreg(a:reg), '^.\{-}\zs\n')  " -- w/o,  '\n\zs' -- with
  let h = a:msg . len(l) . 'L> '
  let maxlen = min([ len(l[0]), &columns - len(h) - 13 ])
  echo h . substitute(l[0][0:l:maxlen], "\t", " ", 'g')
endfunction

function! GetVisualSelection(...)
  " Why is this not a built-in Vim script function?!
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return a:0 >= 1 ? join(lines, a:1) : lines
endfunction

function! TrimLines(str)
  return substitute(a:str, '^[\n\s]\+\(.*\)[\n\s]\+$', '\1', 'g')
endfunction

function! CopyStringInReg(r1, str)
  call setreg('9',  a:r1,  'c') " Preserve previous buffer
  call setreg(a:r1, a:str, 'c')
  call CountLinesInRegister(a:r1, '@'.a:r1.':')
endfunction

function! GetLineBookmark(text, ...)
  let path= a:0>=1 ? expand('%:p') : @%
  let str="\t" . path . ":" . line(".") . a:text
  call CopyStringInReg('+', str)
  " TODO: Add re-indenting of several lines (like 'for' or 'function' part)
  " NOTE: we can add mechanics to insert strings directly to file! or xmind.otl!
endfunction


" Be consistent with C and D which reach the end of line
nnoremap Y y$
" Prevent Paste loosing the register source. Deleted available by "- reg.
"   http://stackoverflow.com/a/7797434/1147859
vnoremap p pgvy
vnoremap P Pgvy
noremap  zp "0p
noremap  zP "0P

" Operator mappings
map <leader>y "+y
map <leader>p "+p
map <leader>P "+P
map <leader>l "+d
map <leader>L "+D
" Send shizzle to the black hole (Remove)
map <leader>r "_d
map <leader>R "_D

" Append to copy buffer
" nnoremap <leader><leader>y :<C-U>call CopyStringInReg('+', @+ . @")<CR>
vnoremap gy :<C-U>call CopyStringInReg('"', @" . GetVisualSelection("\n"))<CR>

" Duplicate unnamed and copy registers
nnoremap <C-y> :<C-U>call CopyStringInReg('+', @")<CR>
vnoremap <C-y> :<C-U>call CopyStringInReg('+', GetVisualSelection("\n"))<CR>
nnoremap <C-p> :<C-U>call CopyStringInReg('"', @+)<CR>
vnoremap <C-p> :<C-U>call CopyStringInReg('"', @+)<CR>gv"+P

nnoremap <leader><C-y> :<C-U>call CopyStringInReg('+', TrimLines(@"))<CR>
vnoremap <leader><C-y> :<C-U>call CopyStringInReg('+', TrimLines(GetVisualSelection("\n")))<CR>
nnoremap <leader><C-p> :<C-U>call CopyStringInReg('"', TrimLines(@+))<CR>
vnoremap <leader><C-p> :<C-U>call CopyStringInReg('"', TrimLines(@+))<CR>gv"+P

" Yank full line w/o newline and surrounded spaces
nnoremap <leader>Y mz^vg_:<C-U>call CopyStringInReg('+', GetVisualSelection("\n"))<CR>`z
" Copy from prompt ':' or '/'. Paste in them by <C-R>+ or <C-R>".
cnoremap <C-y> <C-R>=CopyStringInReg('+', getcmdline())<CR><C-H>
" To be able copy/paste regex snippets into vim/snippets/vim_regex.otl
nnoremap <leader>/ :<C-U>call CopyStringInReg('/', @+)<CR>
vnoremap <leader>/ :<C-U><C-R>=TrimLines(GetVisualSelection('\n')))<CR>
" Open commandline with copied text
nnoremap <leader>; :<C-R>"
vnoremap <leader>; :<C-U><C-R>=GetVisualSelection(" ")<CR>


let s:leader = g:mapleader
let mapleader = "\\"
  nnoremap <leader>Y :<C-U>call GetLineBookmark('')<CR>
  nnoremap <leader>t :<C-U>call GetLineBookmark("\n\t".getline('.'))<CR>
  vnoremap <leader>t :<C-U>call GetLineBookmark("\n\t".GetVisualSelection("\n\t"))<CR>
let mapleader = s:leader

nnoremap <leader>a :<C-U>Ag -w '<C-R><C-W>'<CR>
vnoremap <leader>a :<C-U>Ag -Q '<C-R>=GetVisualSelection(" ")<CR>'<CR>
" vnoremap <leader>A :<C-U>Ag -w -Q '<C-R>=GetVisualSelection(" ")<CR>'<CR>
" vnoremap <leader>a :<C-U>Ag! '<C-R>=substitute(GetVisualSelection(" "),"\([\\\]\[]\)","\\\1","g")<CR>'<CR>

" UNUSED:
" Swap registry
" noremap  <M-c> :let @a=@" \| let @"=@+ \| let @+=@a \| reg "+<CR><CR>
"" Don't use paste in cmap as I use C-n, C-p for navigation in command line
"cmap <F7> <C-\>eescape(getcmdline(), ' \')<CR> "setreg(''+'', getreg('':''))
