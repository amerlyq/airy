"{{{1 Tab/Space ============================
set smarttab       " Smart insert tab setting.
set expandtab      " Exchange tab to spaces.
set tabstop=4      " Substitute <Tab> with blanks.
set softtabstop=4  " Spaces instead <Tab>.
set shiftwidth=4   " Autoindent width.
set shiftround     " Round indent by shiftwidth.


"{{{1 Indent/Format ============================
set autoindent             " automatically indent new lines
set cindent nosmartindent  " used cindent for votl topic aligning on 'cc'
set commentstring=#\ %s  " Use sh-style comments by default instead of c-style
" set formatexpr=autofmt#japanese#formatexpr()  " Use autofmt.


"{{{1 Multiline ============================
set linebreak         " wrap only on \s chars
" set breakat=\ \	;:,!?
set showbreak=\
" Move by arrow keys on previous/next line around ends of line in command mode
set whichwrap=<,>
set backspace=indent,eol,start  " delete indent and newline

set wrap breakindent
noremap <unique> <Leader>tW :<C-u>setl wrap! breakindent!<CR>


"{{{1 Clipboard ============================
" TRY use copy-always -- and keep yank-history by copyq
if has('unnamedplus')
  set clipboard& clipboard+=unnamedplus
else
  set clipboard& clipboard+=unnamed
endif


"{{{1 Completion ============================
set matchpairs+=<:>,=:;     " Match pairs (NOTE ;/= is useful for C/Java)
set infercase       " ignore case on insert completion.
" In python this scratch window made me angry
" autocmd FileType python setlocal completeopt-=preview
set completeopt-=preview


"{{{1 Edit ============================
set history=9999        " remember last commands & searche patts
set virtualedit=block,insert  " TRY cursor can be positioned anywhere in INSERT and V-BLOCK mode
set nodigraph  " No more esc-insert mess when unindented typing wierd characters
set notildeop  " Allow moves for register change, like  ~w -- for word


"{{{1 Moving ============================
set scrolloff=3   " context lines around cursor not hiding when scroll
set scrolljump=5  " minimum number of lines to scroll


" Set keyword help.
set keywordprg=:help
" Check timestamp more for 'autoread'.
autocmd MyAutoCmd WinEnter * checktime
set cursorline      " highlight currently focused line
