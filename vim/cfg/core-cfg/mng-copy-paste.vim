" vim:ts=2:sw=2:sts=2
" NOTE: cmap: C-R,C-G inserts current file name
" ONELINE: :nmap cp :let @+ = "  ".expand("%:p").":".line(".").":\n    ".substitute(getline("."),'^\s\+','','')<CR>
":s;|;\\^M|;g  | split pipe on multiline
"To comment (instead of C-V): select by S-V, then type : s/^/#
" list all occurrences of word under cursor in current buffer: [I
" SEE: http://www.ibm.com/developerworks/library/l-vim-script-2/
" MUST SEE: https://github.com/svermeulen/vim-easyclip


" Highlight Yanked Region in Nvim/Vim - jdhao's blog ⌇⡡⢨⠆⡲
"   https://jdhao.github.io/2020/05/22/highlight_yank_region_nvim/
augroup TextYank
  autocmd!
  au TextYankPost * silent! lua vim.highlight.on_yank{higroup="TextYank", timeout=130}
  au ColorScheme * highlight TextYank term=reverse cterm=reverse gui=reverse
augroup END


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
  " BUG:(strlen/oldvim): when lines are mixed tabs with spaces
  let m=strdisplaywidth(a:s1) | let n=strdisplaywidth(a:s2)
  return m == n ? 0 : m > n ? 1 : -1
endfunc

function! TrimLines(str)
  return substitute(a:str, '\v^\s*\_[ \t]\n?(.{-})\_[ \t\n]*$', '\1', 'g')
endfunction

function! TrimIndents(str,...)
  " BUG: \_^  \_$  don't work
  let t = substitute(a:str, '\v\s+(\ze\n|$)', '', 'g')
  let sil = map(split(t, '\n'), 'matchstr(v:val, "^\\s*")')
  let tir = get(sort(sil, "ShortestIndent"), 0, '')
  " BUG: mixed tab/space -- can't determine common prefix
  return substitute(t, '\v(^|\n$@!\zs)'.tir, get(a:,1,''), 'g')
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""

function! CopyStringInReg(r, str, ...)
 " Preserve previous buffer in register. Breaks next 'setreg'.
  call setreg('p', getreg(a:r, 1), getregtype(a:r))
  call setreg(a:r, a:str, get(a:, 1, getregtype(a:r)))
  call CountLinesInRegister(a:r, '@'. a:r .':')
endfunction

fun! CopyToClipboard(str, ...)
  if &clipboard =~# 'plus'| let r='+'
  elseif &clipboard !=# ''| let r='*'
  else| let r='"' |en
  call call('CopyStringInReg', [r, a:str] + a:000)
endf


" Operator mappings
nnoremap <leader>y "+y
nnoremap [Frame]p "+p
nnoremap [Frame]P "+P
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
" nnoremap <leader><leader>y :<C-U>call CopyToClipboard(@+ . @")<CR>
vnoremap <leader>Y :<C-U>call CopyToClipboard(@" . GetVisualSelection("\n"))<CR>

" Duplicate unnamed and copy registers
nnoremap <C-y> :<C-U>call CopyToClipboard(@")<CR>
vnoremap <C-y> :<C-U>call CopyToClipboard(GetVisualSelection("\n"))<CR>
nnoremap <C-p> :<C-U>call CopyStringInReg('"', @+)<CR>
vnoremap <C-p> :<C-U>call CopyStringInReg('"', @+)<CR>gv"+P

nnoremap <leader><C-y> :<C-U>call CopyToClipboard(TrimLines(@"))<CR>
vnoremap <leader><C-y> :<C-U>call CopyToClipboard(TrimLines(GetVisualSelection("\n")))<CR>
nnoremap <leader><C-p> :<C-U>call CopyStringInReg('"', TrimLines(@+))<CR>
vnoremap <leader><C-p> :<C-U>call CopyStringInReg('"', TrimLines(@+))<CR>gv"+P

" DEPRECATED:('yil'): Yank full line w/o newline and surrounded spaces
" nnoremap <leader>Y mz^vg_:<C-U>call CopyToClipboard(GetVisualSelection("\n"))<CR>`z
" Copy from prompt ':' or '/'. Paste in them by <C-R>+ or <C-R>".
cnoremap <C-y> <C-R>=CopyToClipboard(getcmdline())<CR><C-H>
" To be able copy/paste regex snippets into vim/snippets/vim_regex.otl
" DISABLED: conflicts with Limio -- '<Leader><Space>' paused
" nnoremap <leader><Space>/ :<C-U>call CopyToClipboard(@/)<CR>
" vnoremap <leader><Space>/ :<C-U><C-R>=TrimLines(GetVisualSelection('\n')))<CR>
"" NOTE: copy current path DFL: let @" = expand('%:p:~') ALT: 1<C-g>
noremap  [Frame]%  :<C-U>call CopyToClipboard(expand('%:p:~'))<CR>
noremap  <leader>% :<C-U>call CopyToClipboard('./'.expand('%:t'))<CR>
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
nnoremap <silent><unique>  <Leader>p  :RegConvert b<CR>p
nnoremap <silent><unique>  <Leader>P  :RegConvert b<CR>P

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
" nnoremap <unique>  [Frame]Y  :call GetLineBookmark(v:count,'')<CR>
nnoremap <unique>  [Frame]y  :call GetLineBookmark(v:count, getline('.'))<CR>
vnoremap <unique>  [Frame]y  :<C-U>call GetLineBookmark(v:count, GetVisualSelection("\n"))<CR>

" TODO:DEV: set print format on the fly ":GetLineBookmarkFormat  // {h}\n\t{b:1:1}\n\t\t{b:2}"
"   => different documents and languages require different format of indented/aligned bookmarks
function! GetLineBookmark(idt, text, ...)
  let path = a:0>=1 ? expand('%:p') : @%
  let tab = "  "
  let idfl= 2
  "" Can't use, as values must be extracted from dst, not from src
  "repeat(&et ? repeat(" ", &ts) : "\t", a:idt)
  let prf = repeat(l:tab, (a:idt ? a:idt : idfl))
  let bpfx = l:prf . l:tab

  " NOTE: add context-dependent location prefix '//'
  if strpart(path,0,1) != '/'| let path = '//' . path |en

  let str = l:prf . path .':'. line('.')
  let str.= "\n" . TrimIndents(a:text, bpfx)

  call CopyToClipboard(l:str, 'V')
  " TODO: Add re-indenting of several lines (like 'for' or 'function' part)
  " NOTE: we can add mechanics to insert strings directly to file! or xmind.otl!
endfunction

" TODO:DEV: use "3[Frame].y" to <fixate> current copy-indent to "3"
"   => useful when copying sources outline function by function
nnoremap <unique>  [Frame]gy
  \ :<C-u>call GetLineSpoiler(v:count1, TrimIndents(getline('.')), 1)<CR>
vnoremap <unique>  [Frame]gy
  \ :<C-U>call GetLineSpoiler(v:count1, TrimIndents(GetVisualSelection("\n")), 1)<CR>

nnoremap <unique>  [Frame]gY
  \ :<C-u>call GetLineSpoiler(v:count1, TrimIndents(getline('.')), 0)<CR>
vnoremap <unique>  [Frame]gY
  \ :<C-u>call GetLineSpoiler(v:count1, TrimIndents(GetVisualSelection("\n")), 0)<CR>

""" New legend annotation
"  * path on the right, aligned on 50-60'th column
"  * rest of wide string over 50-60 is annotated by \{+ ... +\}
"  * if lesser -- pad left by spaces
"  * annotation is concealed completely with replace char is …
" E.G. static void dl_main (const Elf{+W(Phdr) *phdr,+}   ./elf/rtld.c:719
" ENH: options
"  * trim text instead of spoilering
"  * use old format for long paths/funds -- path:lnum:\n:\t:func()
"  * use word/funcname under cursor
"  * enforce pivot dir to make paths related to it instead of diff lwd
"   HACK: use tags in pwd but trim paths common prf USE: java nested paths
fun! GetLineSpoiler(idt, text, ...)
  " TODO: g:line_spoiler_width = 50
  "   => so I can change DFL params of snippet at any time
  let n = 50
  let p = expand(get(a:,2) ? '%:p' : '%')
  if p !~# '^[./]'| let p = './'.p |en

  " Expand all blanks in selection
  let t = substitute(a:text, '\s\+',
    \ '\=repeat(" ", strdisplaywidth(submatch(0)))', 'g')
  " Strip C-style line ends
  let t = substitute(t, '\v;?\s*%(\\n)?\\?(\ze\n|$)', '', 'g')

  " WARN: supports fixed indent only == can't use "\t"
  "   * space-padding for *.nou won't work if &ts diffs from *.c
  "   * expand "\t" in above is wrong when &ts diffs in *.c / *.nou
  let i = repeat('  ', a:idt)

  if get(a:,1)  " Join all lines into single one
    let t = l:i . substitute(t, '\n\s*', ' ', 'g')
  else  " Add indent to each line
    let t = substitute(t, '\v(^|\n\zs$@!)', l:i, 'g')
  endif

  if !get(a:,1)
    let m = split(t, "\n")
    let t = get(m, 0, '')
  endif

  " BUG: "\t" matches as single char in ".{50}" instead of &ts
  "" NOTE: Hide into spoiler {+ ... +}
  " if l:n < strdisplaywidth(t)
  "   let t = substitute(t, '\v^.{'.(n-2).'}\zs.*', '{+&+}', '')
  " endif

  "" TRY:BET: pipe through ctags => extract tag name
  if l:n<strdisplaywidth(t)|let t = substitute(t, '\v\)\zs[^)]*$', '', '')|en
  if l:n<strdisplaywidth(t)|let t = substitute(t, '\v^.{'.(n-4).'}.{-}\zs[^()]*\)', '...)', '')|en
  " BUG: corrupts 'if/while' statements => FIXME: apply cutting only to function signatures
  "   ALT: apply prefix cutting only on demand
  if l:n<strdisplaywidth(t)|let t = substitute(t, '\v^\s*\zs[^()]{-}\ze\S*\S{,'.(n-4).'}$', '... ', '')|en
  " if l:n<strdisplaywidth(t)|let t = substitute(t, '\v^\s*\zs.{-}\ze\S{,'.(n-4).'}$', '... ', '')|en
  if l:n<strdisplaywidth(t)|let t = substitute(t, '... ', '', '')|en
  if l:n<strdisplaywidth(t)|let t = substitute(t, '(...)', '()', '')|en

  let t.= repeat(' ', n - strdisplaywidth(t))
  let t.= ' | ' . l:p . ':' . line(".")

  if !get(a:,1) && len(m)>0| let t = join([t] + m[1:], "\n") |en

  call CopyToClipboard(t, 'V')
endf


"{{{1 UNUSED:
" Swap registry
" noremap  <M-c> :let @a=@" \| let @"=@+ \| let @+=@a \| reg "+<CR><CR>
" HACK xnoremap <silent> y "*y:let [@+,@"]=[@*,@*]<CR>
"" Don't use paste in cmap as I use C-n, C-p for navigation in command line
"cmap <F7> <C-\>eescape(getcmdline(), ' \')<CR> "setreg(''+'', getreg('':''))
