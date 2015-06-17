" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1

" WARNING: will not work nicely with light themes, as cursor will remain white
"   I must use t_SI, t_EI here to setup colors? And integrate it with vim-term-focus...
"   OR: simply toggle whole urxvt theme instead.
if !exists('g:forced_theme')
  try  " Load theme name
    let s:theme = readfile(expand('$CACHE/vim_theme'))[0]
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


if s:theme ==# 'transparent'
  " Restore right colors for sign column in solarized
  " TODO: check -- simply use this patch always. Will it work?
  augroup PatchSolarized "{{{2
    autocmd!
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
  au ColorScheme * highlight! link SignColumn LineNr
endif

autocmd ColorScheme * highlight! link ColorColumn StatusLineNC
" Suppress transparency on reverse cursor of search results highlight
autocmd ColorScheme * highlight Search cterm=None ctermbg=3 ctermfg=0
" The "NonText" highlighting will be used for "eol", "extends" and
"  "precedes".  "SpecialKey" for "nbsp", "tab" and "trail".
autocmd ColorScheme * highlight! SpecialKey  ctermbg=None cterm=None
autocmd ColorScheme * highlight! NonText  ctermbg=None


" for molokai
" let g:rehash256 = 1
" nocturne
exec 'set background='. s:theme_bkgr
try
  if exists('$TMUX') | color slate | else | color solarized | endif
catch /^Vim\%((\a\+)\)\=:E185/
  color slate
endtry

" Fix for GitGutter
" highlight GitGutterChange ctermfg=yellow guifg=darkyellow
" highlight GitGutterAdd ctermfg=green guifg=darkgreen
" highlight GitGutterDelete ctermfg=red guifg=darkred
" highlight GitGutterChangeDelete ctermfg=yellow guifg=darkyellow
