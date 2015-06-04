" vim:ts=2:sw=2:sts=2:fdm=marker:fdl=1
let g:theme_transparent = 0

if g:theme_transparent
  let g:solarized_termtrans=1         " use term transparent color for bg
  let g:airline_theme='serene'
  " Restore right colors for sign column in solarized
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
let g:rehash256 = 1


let s:vim_theme=expand('$CACHE/vim_theme')
if filereadable(s:vim_theme)
  exec 'source ' . s:vim_theme
else
  set background=dark "light
  try  "molokai nocturne
    if exists('$TMUX') | color slate | else | color solarized | endif
  catch /^Vim\%((\a\+)\)\=:E185/
    color slate
  endtry
endif

" Fix for GitGutter
" highlight GitGutterChange ctermfg=yellow guifg=darkyellow
" highlight GitGutterAdd ctermfg=green guifg=darkgreen
" highlight GitGutterDelete ctermfg=red guifg=darkred
" highlight GitGutterChangeDelete ctermfg=yellow guifg=darkyellow
" TODO?
"" Highlight pidgin logs:
function! PidginHL()
  syntax match pidginMe '^([^)]\+) me:'
  syntax match pidginOther '\v^\([^)]+\)( me)@!.*:'

  highlight link pidginMe Type
  highlight link pidginOther Identifier
endfunction
command! -bar -nargs=0 PidginHL call PidginHL()
