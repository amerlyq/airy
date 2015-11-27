" WARNING: will not work nicely with light themes, as cursor will remain white
"   I must use t_SI, t_EI here to setup colors? And integrate it with vim-term-focus...
"   OR: simply toggle whole urxvt theme instead.
if !exists('g:forced_theme')
  try  " Load theme name
    let s:theme = readfile(expand('$HOME/.cache/airy/theme'))[0]
  catch /^Vim\%((\a\+)\)\=:E484/
    let s:theme = 'dark'
  endtry
else
  let s:theme = g:forced_theme
endif

if s:theme ==# 'transparent'
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
  if s:theme ==# 'transparent'
    for g in [DiffAdd, DiffChange, DiffDelete, DiffText,
      \       SignColumn, LineNr, FoldColumn, SpecialKey]
      exe 'hi! '.g.' ctermbg=None'
    endfor
  else
    " Restore right colors for sign column in solarized
    " TODO: check -- simply use this patch always. Will it work?
    hi! link SignColumn LineNr
    hi! IndentGuidesOdd  ctermfg=8 ctermbg=0
    hi! IndentGuidesEven ctermfg=8 ctermbg=0
  endif
  hi! Folded cterm=bold ctermfg=11 ctermbg=0 guifg=Cyan guibg=DarkGrey
  " hi! Folded cterm=underline ctermfg=11 ctermbg=NONE guifg=Cyan guibg=DarkGrey
  "  hi! FoldColumn ctermfg=4 ctermbg=NONE guifg=Cyan guibg=Grey
  hi! lCursor guifg=NONE ctermbg=4 guibg=Cyan
  hi! link ColorColumn StatusLineNC
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
endf

augroup PatchColorScheme
  autocmd!
  au ColorScheme * call s:PatchColorScheme()
augroup END

" for molokai
" let g:rehash256 = 1
" nocturne
let &background=s:theme_bkgr
