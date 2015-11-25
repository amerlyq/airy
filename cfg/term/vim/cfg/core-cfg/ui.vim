set list            " display otherwise invisible characters
set listchars=tab:▸\ ,trail:·,extends:»,precedes:«,nbsp:~  ",eol:¬
" if IsWindows() | set listchars=tab:\\_,trail:-,extends:>,precedes:< | endif

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


set confirm         " ask user before aborting an action
set novisualbell    " don't flash the screen
set shortmess=atTIO " No intro msg, etc
" set cmdheight=2   " No hit <CR> twice after :make (but lose one view line)
" If you accidentally hit or and you want to see the displayed text then use
" |g<|. This only works when 'more' is set.
"       Reset 'showcmd' and/or 'ruler'.
" If set nomore -> the prompts will be no more

" To be able safely save sessions and change settings between them
set sessionoptions-=options


set lazyredraw        " don't redraw screen while macros are executing
set colorcolumn=+1    " show textwidth limit

set guicursor+=a:blinkwait0 " disable cursor blink in gvim
"set guiheadroom=0

if has("gui_running")
  if !IsWindows()
    noremap <ScrollWheelUp>   <C-Y>
    noremap <ScrollWheelDown> <C-E>
  endif
  if has("gui_gtk2")
    set guifont=PragmataPro\ 12,DejaVu\ Sans\ Mono\ for\ Powerline\ 11,DejaVu\ Sans\ Mono\ 11
  elseif has("x11")
    set guifont=-*-courier-medium-r-normal-*-*-180-*-*-m-*-*
  elseif has("win32") || has("win64")
    set guifont=DejaVu_Sans_Mono_for_Powerline:h11,Courier_New:h12
  else
    set guifont=Courier_New:h10:cDEFAULT
    "set guifont=-xos4-terminus-medium-r-normal--14-140-72-72-c-80-iso8859-1
  endif
endif
