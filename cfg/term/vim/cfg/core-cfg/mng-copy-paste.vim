" vim:ts=2:sw=2:sts=2
" NOTE: cmap: C-R,C-G inserts current file name
":s;|;\\^M|;g  | split pipe on multiline
"To comment (instead of C-V): select by S-V, then type : s/^/#
" list all occurrences of word under cursor in current buffer: [I
" SEE: http://www.ibm.com/developerworks/library/l-vim-script-2/
" MUST SEE: https://github.com/svermeulen/vim-easyclip

""" Helpers
function! CountLinesInRegister(reg, msg)
  let l = split(getreg(a:reg), '^.\{-}\zs\n', 1)  " -- w/o,  '\n\zs' -- with
  let h = a:msg . len(l) . 'L> '
  let maxlen = min([ len(l[0]), &columns - len(h) - 13 ])
  echo h . substitute(l[0][0:l:maxlen], "\t", " ", 'g')
endfunction

function! GetVisualSelection(...)
  " THINK DEV RFC add:  ():range and use a:firstline, etc -- to exec f once?
  " Why is this not a built-in Vim script function?!
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][: col2 - (&selection == 'inclusive' ? 1 : 2)]
  let lines[0] = lines[0][col1 - 1:]
  return a:0 >= 1 ? join(lines, a:1) : lines
endfunction

"ALT: http://vi.stackexchange.com/questions/2764/send-text-from-one-split-window-to-another
function! CopyToBuffer() range
  let l:lines = GetVisualSelection()
  new
  setl buftype=nofile bufhidden=wipe noswapfile nobuflisted nowrap
  silent put =l:lines
endfunction
command! -bang -nargs=0 -range  CopyToBuffer call CopyToBuffer()
""""""""""""""""""""""""""""""""""""""""""""""""""

function! ShortestIndent(s1, s2)
  let m=strlen(a:s1) | let n=strlen(a:s2)
  return m == n ? 0 : m > n ? 1 : -1
endfunc

function! TrimLines(str)
  return substitute(a:str, '\v^\s*\_[ \t]\n?(.{-})\_[ \t\n]*$', '\1', 'g')
endfunction

function! TrimIndents(str,...)
  let tlst=map(split(a:str, '\n'), 'matchstr(v:val, "^\\s*")')
  " BUG: when lines are mixed tabs with spaces
  let tir=sort(l:tlst, "ShortestIndent")[0]
  let rgx='\v\_^' . l:tir . '(.{-})\s*\_$'
  let feach='substitute(v:val,"^'.l:tir.'","","")'
  return join(map(split(a:str, '\n'),l:feach), (a:0>0?a:1 :'')."\n")
  " return substitute(a:str, l:rgx, (a:0>0?a:1:'').'\1', 'g')
  " return l:tir
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""

function! CopyStringInReg(r, str)
 " Preserve previous buffer in register. Breaks next 'setreg'.
  call setreg('p', getreg(a:r, 1),  getregtype(a:r))
  call setreg(a:r, a:str, getregtype(a:r))
  call CountLinesInRegister(a:r, '@'. a:r .':')
endfunction


" Operator mappings
nnoremap <leader>y "+y
nnoremap <leader>p "+p
nnoremap <leader>P "+P
nnoremap g<leader>p  :put +<CR>
nnoremap g<leader>P  :put!+<CR>
" DISABLED:[unused] Send shizzle to the black hole (Remove)
" map <leader>l "+d
" map <leader>L "+D
" map <leader>r "_d
" map <leader>R "_D

" " Yank buffer's absolute path to X11 clipboard
" nnoremap [unite]y :let @+=expand("%:p")<CR>:echo 'Copied to clipboard.'<CR>

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
" DISABLED: conflicts with Limio -- '<Leader><Space>' paused
" nnoremap <leader><Space>/ :<C-U>call CopyStringInReg('+', @/)<CR>
" vnoremap <leader><Space>/ :<C-U><C-R>=TrimLines(GetVisualSelection('\n')))<CR>
noremap  <leader>% :<C-U>call CopyStringInReg('+', @%)<CR>
" Open commandline with copied text
nnoremap <leader>; :<C-R>"
vnoremap <leader>; :<C-U><C-R>=GetVisualSelection(" ")<CR>

" Directly search copied text
fun! s:putslash(s)
  call histadd('/', a:s)
  call setreg('/', a:s, getregtype('/'))
endf
nnoremap <leader>/ :<C-U>call <SID>putslash('\V'.@+)<CR>/<CR>
nnoremap <leader>? :<C-U>call <SID>putslash('\V'.@+)<CR>?<CR>


"{{{1 Convert main reg type for pasting
" SEE: https://github.com/mutewinter/UnconditionalPaste
nnoremap <silent><unique>  [Frame]t  :RegConvert<CR>
" Force in-line
nnoremap <silent><unique>  [Frame]p  :RegConvert b<CR>p
nnoremap <silent><unique>  [Frame]P  :RegConvert b<CR>P

command! -bar -range=0 -bang -nargs=?  RegConvert
    \ call s:RegConvert(<bang>0, <q-args>)

fun! s:RegConvert(...)
  " CHG: use v:register -- seems like it equivalent to my 'reg'
  if &clipboard =~# 'unnamed'
    let reg = (&clipboard =~# 'plus' ? '+' : '*')
  else
    let reg = (get(a:, 1) ? '+' : '"')
  endif
  let ct = getregtype(reg)
  let nt = get(a:, 2, '')
  if nt ==# ''
    " DISABLED:(cycling) let nt = (ct=~#'c\|v' ? 'l' : (ct =~# 'l\|V' ? 'b' : 'c'))
    let nt = {0: 'c', 1: 'V', 2: 'b'}[v:count]  " EXPL: direct set
  endif
  " CHECK type change isn't sufficient -- need remove newlines and whitespaces
  call setreg(reg, getreg(reg, 1), nt)
  echo printf('"%s: %s -> %s', reg, ct, nt)
endfunction


"{{{1 Get src snippet with ref from current line
" ALT: use keymap [Frame]b because of 'bookmark'
nnoremap <unique>  [Frame]Y  :call GetLineBookmark(v:count,'')<CR>
nnoremap <unique>  [Frame]y  :call GetLineBookmark(v:count1, TrimIndents(getline('.')))<CR>
vnoremap <unique>  [Frame]y  :<C-U>call GetLineBookmark(v:count1, TrimIndents(GetVisualSelection("\n"),"\t"))<CR>

function! GetLineBookmark(tid, text, ...)
  let path= a:0>=1 ? expand('%:p') : @%
  let tab="\t"
  "" Can't use, as values must be extracted from dst, not from src
  "repeat(&et ? repeat(" ", &ts) : "\t", a:tid)
  let prf= repeat(l:tab, a:tid)
  let str=l:prf . path . ":" . line(".")
  let str=l:str . (empty(a:text) ? "" : "\n" . l:prf . l:tab . a:text)
  call CopyStringInReg('+', l:str)
  " TODO: Add re-indenting of several lines (like 'for' or 'function' part)
  " NOTE: we can add mechanics to insert strings directly to file! or xmind.otl!
endfunction


"{{{1 UNUSED:
" Swap registry
" noremap  <M-c> :let @a=@" \| let @"=@+ \| let @+=@a \| reg "+<CR><CR>
" HACK xnoremap <silent> y "*y:let [@+,@"]=[@*,@*]<CR>
"" Don't use paste in cmap as I use C-n, C-p for navigation in command line
"cmap <F7> <C-\>eescape(getcmdline(), ' \')<CR> "setreg(''+'', getreg('':''))
