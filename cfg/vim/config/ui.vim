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

if has('gui_running')
  "colorscheme nocturne
  colorscheme solarized
  "set background=light
  set background=dark
else
  if &t_Co >= 88
    let g:solarized_termcolors=16
    colorscheme solarized
    "colorscheme molokai
    set background=dark
  else
    colorscheme default
  endif
endif

