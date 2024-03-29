set list            " display otherwise invisible characters
set listchars=tab:▸\ ,trail:·,extends:»,precedes:«,nbsp:␣  " ❯❮, eol:¬
" if IsWindows()| set listchars=tab:\\_,trail:-,extends:>,precedes:<,nbsp:~ |en
" set showbreak=\ ↪
" let &showbreak = '⮓ '
set showbreak=..

set nowildmenu      " visual tab-completion variants menu in command mode
set wildmode=list:longest,full          "instead of first-choosing
set showfulltag     " show all info of the tag by supplement of INSERT
set wildoptions=tagfile  " Can supplement a tag in a command-line.
set wildignore+=*.o,*.obj,.git,*.rbc,*.class,.svn,vendor/gems/*

" Never use select(replace) mode by mouse/keyboard. Always use visual.
set selectmode= "empty
set keymodel= "empty


set ruler           " Show cursor position
set showcmd         " Shows last command entered in the very bottom right
set noshowmode      " Don't show current input mode (normal/visual/insert/...)
set laststatus=2    " Show status line always
" Custom command line when no airline or for it's bckgr splits
" set statusline=%f\ %m\ %r\ line:%l/%L(%p%%)\ col:%c\ buf:%n\ (%b)(0x%B)
" set statusline=%02n:%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P
let &statusline="%{winnr('$')>1?'['.winnr().'/'.winnr('$')"
    \ . ".(winnr('#')==winnr()?'#':'').']':''}\ "
    \ . "%{(&previewwindow?'[preview] ':'').expand('%:t')}"
    \ . "\ %=%{(winnr('$')==1 || winnr('#')!=winnr())? '['.(&ft!=''?&ft.',':'')"
    \ . ".(&fenc!=''?&fenc:&enc).','.&ff.']' : ''}"
    \ . "%m%{printf('%'.(len(line('$'))+2).'d/%d',line('.'),line('$'))}"

" Set title in terminal. WARN:BUG: nvim won't restore title back
" TODO: replace simple expand by arline letter-wise compression
set title titlelen=80
let &titlestring = (has('nvim') ? 'neovim' : 'vim') . ':%{expand("%:~")}%m'


set novisualbell    " don't flash the screen
set shortmess=atTIOs " No intro msg, etc FIXED: no hit bottom/top on tagjump
" set cmdheight=2   " No hit <CR> twice after :make (but lose one view line)
" If you accidentally hit or and you want to see the displayed text then use
" |g<|. This only works when 'more' is set.
"       Reset 'showcmd' and/or 'ruler'.
" If set nomore -> the prompts will be no more

" To be able safely save sessions and change settings between them
set sessionoptions-=options
" To not mess when :bnext after opening some more files by ranger
set sessionoptions-=curdir

if !has('nvim') " BUG? interference with nvim window resizing?
  set lazyredraw    " don't redraw screen while macros are executing
endif

if exists('&cc')
  "" HACK: show textwidth limit only before text wraps on big enough screens
  au MyAutoCmd VimResized,WinEnter,WinLeave,BufWinEnter *
        \ let &cc=((&tw > winwidth(0)-&fdc-&nuw-1) && &wrap ? '' : '+1')
endif
