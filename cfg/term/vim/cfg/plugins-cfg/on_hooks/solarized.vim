
" [nxi]map <unique> <F12> <Plug>ToggleBackground

let g:solarized_menu=0

if has('gui_running') || $TERM =~# '\v^%(rxvt|st|tmux|dvtm|screen)'  "\|nvim
  let g:solarized_termcolors=16  " Use only with pre-setup palette!
  let g:airline_theme = 'solarized'
elseif &t_Co > 16  " If ~256 -- makes brown bg and bold font...
  let g:solarized_termcolors=&t_Co  " Choose similar colors from palette
  let g:airline_theme = 'badwolf'  " seren
else | echom "Too much reduced palette for solarized colorscheme" | endif

" let g:solarized_contrast="high"    "high|normal|low  -- stich with normal!
let g:solarized_visibility="low"    "high|normal|low -- for tab/nl/space
let g:solarized_hitrail=0
" g:solarized_termtrans = 0
let g:solarized_bold=1
let g:solarized_underline=1
let g:solarized_italic=1
