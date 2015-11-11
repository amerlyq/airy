" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1

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

augroup PatchColorScheme
  autocmd!
augroup END

if s:theme ==# 'transparent'
  " Restore right colors for sign column in solarized
  " TODO: check -- simply use this patch always. Will it work?
  augroup PatchColorScheme "{{{2
    au ColorScheme * hi DiffAdd    ctermbg=None
    au ColorScheme * hi DiffChange ctermbg=None
    au ColorScheme * hi DiffDelete ctermbg=None
    au ColorScheme * hi DiffText   ctermbg=None
    au ColorScheme * hi SignColumn ctermbg=None
    au ColorScheme * hi LineNr     ctermbg=None
    au ColorScheme * hi FoldColumn ctermbg=None
    au ColorScheme * hi SpecialKey ctermbg=None
  augroup END "}}}2
else
  au PatchColorScheme ColorScheme * highlight! link SignColumn LineNr
endif

augroup PatchColorScheme "{{{2
  au ColorScheme * hi! Folded ctermfg=3 ctermbg=NONE
  " :highlight FoldColumn guibg=darkgrey guifg=white
  au ColorScheme * hi! link ColorColumn StatusLineNC
  " Suppress transparency on reverse cursor of search results highlight
  au ColorScheme * hi Search cterm=None ctermbg=3 ctermfg=0
  " The "NonText" highlighting will be used for "eol", "extends" and
  "  "precedes".  "SpecialKey" for "nbsp", "tab" and "trail".
  au ColorScheme * hi! SpecialKey  ctermbg=None cterm=None
  au ColorScheme * hi! NonText  ctermbg=None
augroup END "}}}2


" for molokai
" let g:rehash256 = 1
" nocturne
exec 'set background='. s:theme_bkgr
try
  if exists('$TMUX') && &t_Co <= 16
    color slate | else | color solarized
  endif
catch /^Vim\%((\a\+)\)\=:E185/
  color slate
endtry

" Fix for GitGutter
" hi! GitGutterChange ctermfg=yellow guifg=darkyellow
" hi! GitGutterAdd ctermfg=green guifg=darkgreen
" hi! GitGutterDelete ctermfg=red guifg=darkred
" hi! GitGutterChangeDelete ctermfg=yellow guifg=darkyellow
