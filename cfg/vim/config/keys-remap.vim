" TRY: inoremap jk <ESC>

" Be consistent with C and D which reach the end of line
nnoremap Y y$

" Now 'a jump you to line and column, and `a only to line
noremap ' `
noremap ` '

" Pinky stratching
noremap ,. :
cnoremap <C-o> <C-p>

" Save keystrokes for Ex-commands
noremap ;  :
"noremap : ,
noremap , <Nop>
noremap [f ;
noremap ]f ,

" No jump when joining
" nnoremap J mzJ`z

" Highlight only. Don't jump.
noremap z# g#
noremap z* g*
noremap <silent> g# #N:<C-U>set hlsearch<CR>
noremap <silent> g* *N:<C-U>set hlsearch<CR>
" Remap for '*' and '#' don't work cause of plugin vim-indexed-search remapping
" vnoremap * y :execute ":let @/=@\""<CR> :execute "set hlsearch"<CR>

" Insert empty line before/after
noremap gO O <C-U><Esc>
noremap go o <C-U><Esc>
inoremap <M-CR> <Esc>o

" Adequate replace tabs by parts, not entirely
noremap R gR

" history-window (when you mistakes) now on 'gq:'
" Use q for formatting the current paragraph (or selection)
" Ex-command availible by gQ
noremap ,q q
vnoremap q gq
nnoremap q gq$
nnoremap Q gqip

" retain relative cursor position when paging
nnoremap <PageUp>   <C-U>
nnoremap <PageDown> <C-D>

" swap vertical line motions with wrapped text
noremap j gj
noremap k gk
noremap gj j
noremap gk k

" more stretching comfort
noremap g0 ^
noremap ,4 $
noremap g4 A<Space><Esc>
noremap ,g %

" Swap v and CTRL-V was pitiful idea
noremap   ,v  <C-V>


" Unused
" map - $
" map # %

"" VISUAL
" selects the last text edited/pasted in INSERT, and reselect of last VISUAL
noremap gv `[v`]
noremap gV gv
"" select last paste in visual mode
nnoremap <expr> gb '`[' . strpart(getregtype(), 0, 1) . '`]'
" visually select a search result
nnoremap g/ //e<cr>v??<cr>
" reselect visual block after indent
vnoremap < <gv
vnoremap > >gv

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
