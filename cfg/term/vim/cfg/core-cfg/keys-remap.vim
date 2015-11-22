"" INSERT "{{{
" TODO TRY -- then I could replace ReleaseEsc on Caps by LatchCtrl
" WARNING This will prevent you from writing such pairs at all (even paste)!
" So, to paste text with them from term you need use 'set paste'
" inoremap jj <Esc>
inoremap jf <Esc>
inoremap fj <Esc>
inoremap ,s <Esc>:update<CR>
" cnoremap <expr> j
"       \ getcmdline()[getcmdpos()-2] ==# 'j' ? "\<BS>\<C-c>" : 'j'
" onoremap jj           <ESC>
" inoremap j<Space>     j
" onoremap j<Space>     j

" Instead of whole line indention
inoremap <C-t>  <C-v><TAB>
" inoremap <C-d>  <Del>  DONE by vim-rsi
" Enable undo for <C-w> and <C-u>.
inoremap <C-w>  <C-g>u<C-w>
inoremap <C-u>  <C-g>u<C-u>

if has('gui_running')
  inoremap <ESC> <ESC>
endif

cnoremap <C-k> <C-\>e getcmdpos() == 1 ?
      \ '' : getcmdline()[:getcmdpos()-2]<CR>
"}}}

" Don't select eol spaces and '\n'. Instead use 'D' or 'DgJ'.
xnoremap <unique> $  g_
xnoremap <unique><expr> v  (mode() ==# "\<C-v>") ? "v" : "\<C-v>"
"I;\<Esc>" : "\<C-v>I;\<Esc>"

" Now 'a jump you to line and column, and `a only to line
noremap <unique> ' `
noremap <unique> ` '
" noremap , <Nop>

" Pinky stretching soothing
cnoremap <unique> <C-o> <C-p>

" Faster $3 ex-cmds
noremap <unique> ;  :

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

" Insert commented out copy under current line, keeps cursor position
nnoremap <unique><silent> gC :call RetainPos('.t.\|norm gcc')<CR>


" Built-in autocompletion, word, line
" inoremap <C-space> <C-x><C-o>
" inoremap <C-space> <C-x><C-l>

" Line split
nnoremap K   a<CR><Right><Esc>
xnoremap K   c<CR><Esc>
nnoremap gK  i<CR><Right><Esc>
nnoremap <C-k> i<CR><Right><Esc>:m .-2<CR>
nnoremap gX  lxh


" Adequate replace tabs by parts, not entirely
noremap <unique> R gR

" history-window (when you mistakes) now on 'gq:'
" Use q for formatting the current paragraph (or selection)
" Ex-command availible by gQ
noremap <unique> ,q q

" retain relative cursor position when paging
nnoremap <unique> <PageUp>   <C-U>
nnoremap <unique> <PageDown> <C-D>

" improve scroll
" noremap <unique><expr> <C-f> max([winheight(0) - 2, 1]) . "\<C-d>" . (line("w$") >= line('$') ? "L" : "H")
" noremap <unique><expr> <C-b> max([winheight(0) - 2, 1]) . "\<C-u>" . (line("w0") <= 1         ? "H" : "L")
" noremap <unique><expr> <C-e> (line("w$") >= line('$') ? "j" : "3\<C-e>")
" noremap <unique><expr> <C-y> (line("w0") <= 1         ? "k" : "3\<C-y>")

" swap vertical line motions with wrapped text
noremap <unique><expr> j v:count ? 'j' : 'gj'
noremap <unique><expr> k v:count ? 'k' : 'gk'
noremap <unique> gj j
noremap <unique> gk k

" more stretching comfort
noremap <unique> g0 ^
noremap <unique> ,4 $
noremap <unique> g4 A<Space><Esc>
noremap <unique> ,g %
" Swap v and CTRL-V was pitiful idea
noremap <unique> ,v  <C-V>

" " Use <C-Space> instead <C-@>
" SEE: What is it?
" nmap <C-Space>  <C-@>
" cmap <C-Space>  <C-@>

" Unused
" map - $
" map # %

"" VISUAL
" Select last paste
" nnoremap <expr> gp '`['.strpart(getregtype(), 0, 1).'`]'
"" select last paste in visual mode
" BUG THINK gv/gV -- has no sense / don't work in VISUAL?
noremap <unique> <expr> gv '`[' . strpart(getregtype(), 0, 1) . '`]'
" selects the last text edited/pasted in INSERT, and reselect of last VISUAL
noremap <unique> gV `[v`]
" visually select a search result (default: 'gn, gN' -- much better!)
nnoremap <unique> z/ //e<CR>v??<CR>
" Go to the first non-blank character of the line after paragraph motions
noremap } }^


"" Indention
nnoremap > >>_
nnoremap < <<_
" USE instead g< for last message -- ':mes' or ':norm! g<'
nnoremap g> >
nnoremap g< <
" reselect visual block after indent
xnoremap <unique> > >gv|
xnoremap <unique> < <gv

" Drag current line/s vertically and auto-indent. (Use Overlay+hjkl)
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

" Tab is Next window
" nnoremap <Tab> <C-W>w
" nnoremap <S-Tab> <C-W>W
