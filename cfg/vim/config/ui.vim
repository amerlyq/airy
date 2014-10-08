set number "relativenumber  " show line numbers relative to cursor
set novisualbell    " don't flash the screen
set laststatus=2    " always show status line
set wildignore+=*.o,*.obj,.git,*.rbc,*.class,.svn,vendor/gems/*
set wildmenu        " tab-completion variants menu in command mode
set wildmode=list:longest,full          "instead of first-choosing
set list            " display otherwise invisible characters

" Make tab char visible
set listchars=tab:\\_,extends:>,precedes:<,nbsp:% ",eol:¬
set noshowmode
set lazyredraw        " don't redraw screen while macros are executing
set mouse=a           " support for mouse wheel and clicks
set colorcolumn=+1    " show textwidth limit
set virtualedit=block " cursor can be positioned where there is no character


autocmd ColorScheme * highlight! link ColorColumn StatusLineNC

let g:theme_transparent = 0

if g:theme_transparent
  let g:solarized_termtrans=1         " use term transparent color for bg
  let g:airline_theme='serene'
  " Restore right colors for sign column in solarized
  autocmd ColorScheme * highlight DiffAdd    ctermbg=None
  autocmd ColorScheme * highlight DiffChange ctermbg=None
  autocmd ColorScheme * highlight DiffDelete ctermbg=None
  autocmd ColorScheme * highlight DiffText   ctermbg=None
  autocmd ColorScheme * highlight SignColumn ctermbg=None
  autocmd ColorScheme * highlight LineNr     ctermbg=None
  autocmd ColorScheme * highlight FoldColumn ctermbg=None
  autocmd ColorScheme * highlight SpecialKey ctermbg=None
else
  set cursorline      " highlight currently focused line
  autocmd ColorScheme * highlight SignColumn ctermbg=0
endif


set background=dark
" set background=light

if exists('$TMUX')
  colorscheme molokai "nocturne
else
  colorscheme solarized
endif

" Fix for GitGutter
" highlight GitGutterChange ctermfg=yellow guifg=darkyellow
" highlight GitGutterAdd ctermfg=green guifg=darkgreen
" highlight GitGutterDelete ctermfg=red guifg=darkred
" highlight GitGutterChangeDelete ctermfg=yellow guifg=darkyellow

set guicursor+=a:blinkwait0 " disable cursor blink in gvim
set guioptions-=r           " disable right scrollbar
set guioptions-=L           " disable left scrollbar
set guioptions-=T           " disable toolbar
set guioptions-=m           " disable menubar
set guioptions+=c           " console-like dialogs instead of gui popup ones

if has("gui_running")
  if has("gui_gtk2")
    set guifont=DejaVu\ Sans\ Mono\ 11   "PragmataPro\ 12
    "set guifont=Courier\ New\ 11
  elseif has("x11")
    set guifont=-*-courier-medium-r-normal-*-*-180-*-*-m-*-*
  elseif has("win32") || has("win64")
    set guifont=DejaVu\ Sans\ Mono\ for\ Powerline:h11
    "set guifont=Consolas:h12
  else
    set guifont=Courier_New:h10:cDEFAULT
    "set guifont=-xos4-terminus-medium-r-normal--14-140-72-72-c-80-iso8859-1
  endif
endif

let g:Powerline_symbols = 'fancy'
"set guiheadroom=0

"- custom command line
set stl=%f\ %m\ %r\ line:%l/%L(%p%%)\ col:%c\ buf:%n\ (%b)(0x%B)

" vim:ts=2:sw=2:sts=2
