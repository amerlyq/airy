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
  autocmd ColorScheme * highlight! link SignColumn LineNr
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


let s:vim_theme=expand('$HOME/.cache/vim/vim_theme')
if filereadable(s:vim_theme)
  exec 'source ' . s:vim_theme
else
  set background=dark "light
  if exists('$TMUX')
    colorscheme solarized  "molokai nocturne
  else
    colorscheme solarized
  endif
endif

" Fix for GitGutter
" highlight GitGutterChange ctermfg=yellow guifg=darkyellow
" highlight GitGutterAdd ctermfg=green guifg=darkgreen
" highlight GitGutterDelete ctermfg=red guifg=darkred
" highlight GitGutterChangeDelete ctermfg=yellow guifg=darkyellow

"" Highlight pidgin logs:
function! PidginHL()
  syntax match pidginMe '^([^)]\+) me:'
  syntax match pidginOther '\v^\([^)]+\)( me)@!.*:'

  highlight link pidginMe Type
  highlight link pidginOther Identifier
endfunction
command! -bar -nargs=0 PidginHL call PidginHL()
