"{{{1 Tab/Space ============================
set smarttab       " Smart insert tab setting.
set expandtab      " Exchange tab to spaces.
set tabstop=4      " Substitute <Tab> with blanks.
set softtabstop=4  " Spaces instead <Tab>.
set shiftwidth=4   " Autoindent width.
set shiftround     " Round indent by shiftwidth.


"{{{1 Indent/Format ============================
set autoindent             " automatically indent new lines
set nocindent         " BAD:(plain text): used for votl topic aligning on 'cc'
set nosmartindent
set cinkeys-=0# indentkeys-=0#  " Restrain vim from messing with '#' indent
set commentstring=#\ %s  " Use sh-style comments by default instead of c-style
" set formatexpr=autofmt#japanese#formatexpr()  " Use autofmt.


"{{{1 Multiline ============================
set linebreak         " wrap only on \s chars
" set breakat=\ \	;:,!?
set showbreak=..
" Move by arrow keys on previous/next line around ends of line in command mode
set whichwrap=<,>
set backspace=indent,eol,start  " delete indent and newline

" if v:version > 704 || (v:version == 704 && has('patch338'))
set wrap |if exists('&bri')|set breakindent|endif
nnoremap <unique> [Toggle]w :setl wrap! wrap?\|if exists('&bri')\|setl bri!\|endif<CR>


"{{{1 Fold/Conceal ============================
set foldenable
set foldcolumn=2        " fold levels ruler on left (clickable)
"set foldmethod=manual  " <expr|syntax|marker> -- syntax defines folds
set foldlevel=0         " close folds below this depth, initially
set foldlevelstart=99   " close folds below this depth, on enter
" set foldopen=all      " open on cursor touch, DISABLED: prevents 'za' fold

if has('conceal')
  set concealcursor=cv  " Concealing -- hide in command and visual modes.
  set conceallevel=2    " Conceal all hidden beside having custom replacement
endif


"{{{1 Completion ============================
set matchpairs+=<:>     " Match pairs
set infercase       " ignore case on insert completion.
" In python this scratch window made me angry
" autocmd FileType python setlocal completeopt-=preview
set completeopt-=preview


"{{{1 Edit ============================
set history=9999        " remember last commands & searche patts
set nodigraph  " No more esc-insert mess when unindented typing wierd characters
set notildeop  " Allow moves for register change, like  ~w -- for word

set virtualedit=block   " cursor can be positioned anywhere in V-BLOCK mode
noremap <unique> [Toggle]v :<C-u>let &virtualedit=(&ve=='all'?'block':'all')\|set ve?<CR>


"{{{1 Moving ============================
set scrolloff=3     " context lines visible at screen edge when scroll
set scrolljump=0    " minimum number of lines to scroll, OR: =-50 (50%)
set sidescroll=16   " horizontal scroll by 1 char (DFL:(0) -- half screen)
set sidescrolloff=4 " keep N columns on side visible when scrolling
set nostartofline   " keep column when  <C-[fbud]> or [ggGHML], :25


"{{{1 Spell ============================
" NOTE: <count> before 'zg' 'zw' -- to access personal/project spellfile
set spellfile=$VIMHOME/spell/en.utf-8.add  " One file of mixed content
set spellcapcheck=  " Don't auto-capitilize suggested words
nnoremap <unique> [Toggle]s  :setl spell! spelllang=en_us,ru_yo,uk spell?<CR>


" Set keyword help.
set keywordprg=:help
" Check timestamp more for 'autoread'.
autocmd MyAutoCmd WinEnter * checktime
nnoremap <unique> [Toggle]a  :setl autoread! hls?<CR>

" UI
set cursorline              " highlight currently focused line
set number |try|set relativenumber|catch/E518/|endt   " show line number
set synmaxcol=200   " limit syntax hi to first 120 chars only

nnoremap <unique> [Toggle]c  :set cursorcolumn! cuc?<CR>
nnoremap <unique> [Toggle]C  :set cursorline! cul?<CR>
nnoremap <unique> [Toggle]A  :let &laststatus=(&ls?0:2) \| :AirlineToggle<CR>
