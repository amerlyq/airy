"" INSERT "{{{

" To put actual ',s' in insert use:  ,<C-d>s
inoremap <unique> ,s <Esc>:update<CR>
inoremap <unique> ,ы <Esc>:update<CR>
inoremap <unique> ,і <Esc>:update<CR>

" Be consistent with C and D which reach the end of line
" DISABLED:SEE:(neovim): same *default-mappings*
" if empty(maparg('Y','n'))| exe 'nnoremap <unique> Y y$' |en
" if empty(maparg('Y','v'))| exe 'vnoremap <unique> Y y$' |en

" Cycle through *.h/*.cpp
if empty(maparg('[f','n'))
  nnoremap <unique> [f :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>
endif

" Prevent Paste loosing the register source. Deleted available by "- reg.
"   http://stackoverflow.com/a/7797434/1147859
" vnoremap <unique> p pgvy
" vnoremap <unique> P Pgvy
"" SRC: neovim - Clipboard is reset after first paste in Visual Mode - Vi and Vim Stack Exchange ⌇⡠⡖⠑⢖
"   https://vi.stackexchange.com/questions/25259/clipboard-is-reset-after-first-paste-in-visual-mode
vnoremap <unique><expr> p 'pgv"'.v:register.'y`>'
vnoremap <unique><expr> P 'Pgv"'.v:register.'y`>'
noremap  <unique> zp "0p
noremap  <unique> zP "0P

"" Forced linewise paste
" SRC: tpope/vim-unimpaired: unimpaired.vim: Pairs of handy bracket mappings ⌇⡠⡖⠋⣉
"   https://github.com/tpope/vim-unimpaired
nnoremap ]p  :<C-u>exe 'put '. v:register<CR>
nnoremap ]P  :<C-u>exe 'put!'. v:register<CR>


" Instead of whole line indention
inoremap <unique> <C-t>  <C-v><TAB>
" inoremap <C-d>  <Del>  DONE by vim-rsi

" Enable undo for <C-w> and <C-u>.
" DISABLED:SEE:(neovim): same *default-mappings*
" inoremap <unique> <C-u>  <C-g>u<C-u>
" inoremap <unique> <C-w>  <C-g>u<C-w>

cnoremap <unique> <C-k> <C-\>e getcmdpos() == 1 ?
      \ '' : getcmdline()[:getcmdpos()-2]<CR>
"}}}

xnoremap <unique><expr> v  (mode() ==# "\<C-v>") ? "v" : "\<C-v>"
"I;\<Esc>" : "\<C-v>I;\<Esc>"

" Now 'a jump you to line and column, and `a only to line
noremap <unique> ' `
noremap <unique> ` '
" Because 'ga' is used by me already
" NICE: https://spin.atomicobject.com/2011/06/21/character-encoding-tricks-for-vim/
noremap <unique> g8 ga

" Pinky stretching soothing
" cnoremap <unique> <C-o> <C-p>
" Faster $3 ex-cmds
noremap <unique> ;  :

" Jumping through :changes list by {g, g;} DUE:(g<Leader>) ※⡟⠱⣔⠚
noremap <unique> g: g,

" Move to <next|prev> [qf|loc] entry
noremap <unique> ]q :<C-U><C-R>=v:count1<CR>cnext!<CR>
noremap <unique> [q :<C-U><C-R>=v:count1<CR>cprevious!<CR>
noremap <unique> ]l :<C-U><C-R>=v:count1<CR>lnext!<CR>
noremap <unique> [l :<C-U><C-R>=v:count1<CR>lprevious!<CR>

" No jump when joining
" nnoremap J mzJ`z
" Here is an example, to replace the selected text with the output of "date":
" :vmap _a <Esc>`>a<CR><Esc>`<i<CR><Esc>!!date<CR>kJJ

" Insert empty line before/after, prepend  <C-u>..
" THINK visual mappings could do smth useful? -- like add line, staing in place
" TRY -- tear out current selection in up/down line for character-wise?
" TRY -- surround by empty lines for linewise?
" ALT http://vim.wikia.com/wiki/Quickly_adding_and_deleting_empty_lines
" NOTE! you can use 'o<C-R>_' to keep indent and not insert any character
nnoremap <unique> go  o<Space><Esc>^"_D
nnoremap <unique> gO  O<Space><Esc>^"_D
nnoremap <unique> g<Leader>o  o<Space><Esc>"_D
nnoremap <unique> g<Leader>O  O<Space><Esc>"_D
" TODO:DEV: visual mappings -- NEED enter one-cmd normal (FIND:HOW)
" xnoremap <unique> go <C-o>go
" xnoremap <unique> gO <C-o>gO
"
" ALT:
" nnoremap <unique> go o<Space><C-u><Esc>
" nnoremap <unique> gO O<Space><C-u><Esc>
" nnoremap <unique> go o<Space><BS><Esc>
" nnoremap <unique> gO O<Space><BS><Esc>
" nnoremap <Enter> :call append(line('.'), '')<CR>
" nnoremap <S-Enter> :call append(line('.')-1, '')<CR>
" nnoremap <silent> ]<Space> :<C-u>put =repeat(nr2char(10),v:count)<Bar>execute "'[-1"<CR>
" nnoremap <silent> [<Space> :<C-u>put!=repeat(nr2char(10),v:count)<Bar>execute "']+1"<CR>

" HACK: Insert commented out copy under current line, keeps cursor position
nnoremap <unique><silent> gcC :call RetainPos(".t.\|norm gcc")<CR>
" xnoremap <unique><silent> gcC :<C-u>call RetainPos("'<,'>t'>\|norm gvgc")<CR>

nnoremap <unique><silent> gC :.t-1\|Commentary\|+1<CR>
xnoremap <unique><silent> gC :'<,'>t'<-1<Bar>'[,']Commentary<Bar>']+1<CR>


" Built-in autocompletion, word, line
" inoremap <C-space> <C-x><C-o>
" inoremap <C-space> <C-x><C-l>

" Line split
nnoremap <unique> K   a<CR><Right><Esc>
xnoremap <unique> K   c<CR><Esc>
nnoremap <unique> gK  i<CR><Right><Esc>
nnoremap <unique> <C-k> i<CR><Right><Esc>:m .-2<CR>
nnoremap <unique> <C-j> :<C-u>+m.-<CR>J
nnoremap <unique> gX  lxh


" Adequate replace tabs by parts, not entirely
noremap <unique> R gR

" history-window (when you mistakes) now on 'gq:'
" Use q for formatting the current paragraph (or selection)
" Ex-command availible by gQ, cedit by 'Q:' o 'Q/'
noremap <unique> Q q

" retain relative cursor position when paging
nnoremap <unique> <PageUp>   <C-U>
nnoremap <unique> <PageDown> <C-D>

" improve scroll
" noremap <unique><expr> <C-f> max([winheight(0) - 2, 1]) . "\<C-d>" . (line("w$") >= line('$') ? "L" : "H")
" noremap <unique><expr> <C-b> max([winheight(0) - 2, 1]) . "\<C-u>" . (line("w0") <= 1         ? "H" : "L")
" noremap <unique><expr> <C-e> (line("w$") >= line('$') ? "j" : "3\<C-e>")
" noremap <unique><expr> <C-y> (line("w0") <= 1         ? "k" : "3\<C-y>")

" Vertical line motions for wrapped text
" BUG: 'showcmd' shows 'j' or 'gj' in haskell -- MAYBE au CursorMoved?
noremap <unique><silent><expr> j v:count ? 'j' : 'gj'
noremap <unique><silent><expr> k v:count ? 'k' : 'gk'
noremap <unique><silent> gj j
noremap <unique><silent> gk k

" more stretching comfort
noremap <unique> g4 A<Space><Esc>
noremap <unique> ,g %

nnoremap <unique> cC :t.<CR>
xnoremap <unique> C :t'><CR>

" " Use <C-Space> instead <C-@>
" SEE: What is it?
" nmap <C-Space>  <C-@>
" cmap <C-Space>  <C-@>

"" VISUAL
" Select last paste
" nnoremap <expr> gp '`['.strpart(getregtype(), 0, 1).'`]'
"" select last paste in visual mode
" BUG THINK gv/gV -- has no sense / don't work in VISUAL?
noremap <unique> <expr> gv '`[' . strpart(getregtype(), 0, 1) . '`]'
" selects the last text edited/pasted in INSERT, and reselect of last VISUAL
noremap <unique> gV `[v`]
" BAD: visually select a search result (default: 'gn, gN' -- much better!)
" nnoremap <unique> z/ //e<CR>v??<CR>
" Go to the first non-blank character of the line after paragraph motions
noremap } }^


"" Indention.
" USE: instead 'g<' -- ':mes' or ':norm! g<'
nnoremap <unique>  >  >>_
nnoremap <unique>  <  <<_
nnoremap <unique>  g>  >
nnoremap <unique>  g<  <
" Re-select visual block after indent
xnoremap <unique>  >  >gv|
xnoremap <unique>  <  <gv

" I more often do upper-case than lower-case
noremap <unique>  gu  gU
noremap <unique>  gU  gu


" HACK: Drag curr line/s vertically and auto-indent. (USE: Overlay+[hjkl])
nnoremap <unique> <S-Up>    :m-2<CR>==
nnoremap <unique> <S-Down>  :m+<CR>==
xnoremap <unique> <S-Up>    :m-2<CR>gv=gv
xnoremap <unique> <S-Down>  :m'>+<CR>gv=gv

" works cool only with xkb map of arrows to C-hjkl
" nnoremap <C-PageUp>    <Esc>:tabprev<CR>
" nnoremap <C-PageDown>  <Esc>:tabnext<CR>
" nnoremap [t <Esc>:tabprev<CR>
" nnoremap ]t <Esc>:tabnext<CR>

" use Alt-Left and Alt-Right to move current tab to left or right
" nnoremap <silent> <A-Left> :execute 'silent! tabmove ' . (tabpagenr()-2)<CR>
" nnoremap <silent> <A-Right> :execute 'silent! tabmove ' . tabpagenr()<CR>
