" WARNING: will not work nicely with light themes, as cursor will remain white
"   I must use t_SI, t_EI here to setup colors? And integrate it with vim-term-focus...
"   OR: simply toggle whole urxvt theme instead.
if !exists('g:forced_theme')
  try  " Load theme name
    let s:theme = readfile(expand('$HOME/.config/airy/theme'))[0]
  catch /^Vim\%((\a\+)\)\=:E484/
    let s:theme = 'dark'
  endtry
else
  let s:theme = g:forced_theme
endif

if s:theme ==# 'transparent'
  set t_ut=y  " erase background
  let s:theme_bkgr = 'dark'
  let g:airline_theme = 'serene'
  let g:solarized_termtrans=1         " use term transparent color for bg

  set nocursorline      " disable highlighting currently focused line
elseif s:theme ==# 'dark'
  let s:theme_bkgr = 'dark'
elseif s:theme ==# 'light'
  let s:theme_bkgr = 'light'
else
  echom 'No such theme: '. s:theme
  let s:theme_bkgr = 'dark'
endif

fun! s:PatchColorScheme()
  set t_ut=  " Don't erase bkgr. See http://sunaku.github.io/vim-256color-bce.html
  if s:theme ==# 'transparent'
    for g in [DiffAdd, DiffChange, DiffDelete, DiffText,
      \       SignColumn, LineNr, FoldColumn, SpecialKey]
      exe 'hi! '.g.' ctermbg=None'
    endfor
  else
    " Restore right colors for sign column in solarized
    " TODO: check -- simply use this patch always. Will it work?
    hi! link SignColumn LineNr
    hi! IndentGuidesOdd  ctermfg=8 ctermbg=0 guifg=#002b36 guibg=#072f3b
    hi! IndentGuidesEven ctermfg=8 ctermbg=0 guifg=#002b36 guibg=#072f3b
  endif
  hi! Folded cterm=bold ctermfg=11 ctermbg=0 gui=bold guifg=#657b83 guibg=#073240
  " hi! Folded cterm=underline ctermfg=11 ctermbg=NONE guifg=Cyan guibg=DarkGrey
  "  hi! FoldColumn ctermfg=4 ctermbg=NONE guifg=Cyan guibg=Grey

  "" BET: hi! Cursor ctermbg=BG guibg=BG
  " hi! Cursor ctermbg=15 guibg=#eeeeee
  " hi! iCursor ctermbg=6 guibg=#00ffff
  " hi! rCursor ctermbg=2 guibg=#00ff00
  " hi! oCursor ctermbg=5 guibg=#ff00ff

  hi! link ColorColumn StatusLineNC
  " TRY (v.1.5.0?)
  hi! link QuickFixLine TermCursor
  " Suppress transparency on reverse cursor of search results highlight
  "  hi! Search cterm=None ctermbg=3 ctermfg=0
  " The "NonText" highlighting will be used for "eol", "extends" and
  "  "precedes".  "SpecialKey" for "nbsp", "tab" and "trail".
  hi! SpecialKey  ctermbg=None cterm=None
  hi! NonText  ctermbg=None
  " Fix for GitGutter
  " hi! GitGutterChange ctermfg=yellow guifg=darkyellow
  " hi! GitGutterAdd ctermfg=green guifg=darkgreen
  " hi! GitGutterDelete ctermfg=red guifg=darkred
  " hi! GitGutterChangeDelete ctermfg=yellow guifg=darkyellow

  " FIXED new "nvim/syntax/diff.vim"
  hi! link diffLine Identifier
  hi! link diffAdded Statement
endf

augroup PatchColorScheme
  autocmd!
  au ColorScheme * call s:PatchColorScheme()
augroup END

" for molokai
" let g:rehash256 = 1
" nocturne
let &background=s:theme_bkgr
