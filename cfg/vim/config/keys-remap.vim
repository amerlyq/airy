"let mapleader=","
"noremap \ ,
" give it a try
inoremap jj <ESC>

" be consistent with C and D which reach the end of line
nnoremap Y y$


" Now 'a jump you to line and column, and `a only to line
nnoremap ' `
nnoremap ` '

" Save keystrokes for Ex-commands
noremap ; :
noremap @; @:
"noremap : ,
noremap , ;

" noremap o o<Esc><Up>
" noremap O O<Esc><Down>

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

