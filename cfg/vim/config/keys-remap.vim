" give it a try
"inoremap jj <ESC>

" Be consistent with C and D which reach the end of line
nnoremap Y y$

" Now 'a jump you to line and column, and `a only to line
nnoremap ' `
nnoremap ` '

" Save keystrokes for Ex-commands
noremap ; :
noremap @; @:
"noremap : ,
" noremap , ;
noremap [f ;
noremap ]f ,


" Highlight only. Don't jump.
noremap z# g#
noremap z* g*
noremap <silent> g# #N:<C-U>set hlsearch<CR>
noremap <silent> g* *N:<C-U>set hlsearch<CR>
" Remap for '*' and '#' don't work cause of plugin vim-indexed-search remapping
" vnoremap * y :execute ":let @/=@\""<CR> :execute "set hlsearch"<CR>

" Line split
nnoremap K  a<CR><Right><Esc>
nnoremap gK i<CR><Right><Esc>

nnoremap gX a<Del><Esc>

" Insert empty line before/after
noremap gO O <C-U><Esc>
noremap go o <C-U><Esc>
inoremap <M-CR> <Esc>o

" Adequate replace tabs by parts, not entirely
noremap R gR
" TODO: map gR to 3gR -> replace 3 chars and return, instead of 3-times repeat

" remove history-window (when you mistakes)
nnoremap q: q;
" Use q for formatting the current paragraph (or selection)
" Ex-command availible by gQ
noremap Q q
vnoremap q gq
nnoremap q Vgq
"gqap

" retain relative cursor position when paging
nnoremap <PageUp>   <C-U>
nnoremap <PageDown> <C-D>

" swap vertical line motions with wrapped text
noremap j gj
noremap k gk
noremap gj j
noremap gk k

" swap v and CTRL-V because Block mode is more useful that Visual mode
nnoremap    v   <C-V>
nnoremap <C-V>     v
vnoremap    v   <C-V>
vnoremap <C-V>     v

" Unused
" map - $
" map # %

"" VISUAL
" select the last edited or pasted text, added last time you were in INSERT
nnoremap gv `[v`]
"" select last paste in visual mode
nnoremap <expr> gb '`[' . strpart(getregtype(), 0, 1) . '`]'
" visually select a search result
nnoremap g/ //e<cr>v??<cr>
" reselect visual block after indent
vnoremap < <gv
vnoremap > >gv

" BUFFERS
noremap  zJ  zj
noremap  zK  zk
noremap  zh  <C-W>h
noremap  zj  <C-W>j
noremap  zk  <C-W>k
noremap  zl  <C-W>l
" switch to adjacent buffer in current window
noremap  gh  :<C-U>bprev<CR>
noremap  gl  :<C-U>bnext<CR>
noremap  gH  :<C-U>bfirst<CR>
noremap  gL  :<C-U>blast<CR>
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
