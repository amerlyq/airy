set cursorline      " highlight currently focused line
set number "relativenumber  " show line numbers relative to cursor
set novisualbell    " don't flash the screen
set laststatus=2    " always show status line
set wildignore+=*.o,*.obj,.git,*.rbc,*.class,.svn,vendor/gems/*
set wildmenu        " tab-completion variants menu in command mode
set wildmode=list:longest,full          "instead of first-choosing
set list            " display otherwise invisible characters
"nnoremap <leader>tl :set list!<CR>
" Make tab char visible
set listchars=tab:\\_,extends:>,precedes:<,nbsp:% ",eol:¬
set noshowmode
set lazyredraw      " don't redraw screen while macros are executing
set mouse=a

set colorcolumn=+1 " show textwidth limit
autocmd ColorScheme * highlight! link ColorColumn StatusLineNC

set background=dark "light
"colorscheme nocturne "molokai
" Restore right colors for sign column in solarized
highlight SignColumn ctermbg=0

" Fix for GitGutter
" highlight GitGutterAdd ctermfg=green guifg=darkgreen
" highlight GitGutterChange ctermfg=yellow guifg=darkyellow
" highlight GitGutterDelete ctermfg=red guifg=darkred
" highlight GitGutterChangeDelete ctermfg=yellow guifg=darkyellow

