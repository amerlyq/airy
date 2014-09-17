"let mapleader=","
"noremap \ ,
"noremap <Leader>d "_d
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
noremap , ;

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

" Insert empty line before/after
noremap gO O <C-U><Esc>
noremap go o <C-U><Esc>
inoremap <M-CR> <Esc>o

" Adequate replace tabs by parts, not entirely
noremap R gR
" TODO: map gR to 3gR -> replace 3 chars and return, instead of 3-times repeat

" remove history-window (when you mistakes)
nnoremap q: q;
" Use Q for formatting the current paragraph (or selection)
" Ex-command availible by gQ
vnoremap Q gq
nnoremap Q Vgq
"gqap

" retain relative cursor position when paging
nnoremap <PageUp>   <C-U>
nnoremap <PageDown> <C-D>

" swap vertical line motions with wrapped text
noremap j gj
noremap k gk
noremap gj j
noremap gk k

" Unused
" map - $
" map # %
"
" imap <C-j> <Down>
" imap <C-k> <Up>
" imap <C-h> <Left>
" imap <C-l> <Right>

