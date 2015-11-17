if $TERM =~# '^rxvt'  "\|nvim
  " Use solarized only with pre-setup palette!
  let g:solarized_termcolors=16
elseif &t_Co > 16
  "If 256 -- choose from existing palette similar colors:
  "   makes brown bg and bold font...
  let g:solarized_termcolors=&t_Co
  let g:airline_theme = 'badwolf'  " seren
else
  echom "Too much reduced palette for solarized colorscheme"
endif

" g:solarized_termtrans = 0
" let g:solarized_contrast="high"    "high|normal|low  -- stich with normal!
let g:solarized_visibility="low"    "high|normal|low -- for tab/nl/space
let g:solarized_hitrail=0

let g:solarized_menu=0
let g:solarized_bold=1
let g:solarized_underline=1
let g:solarized_italic=1

" nmap <unique> <F12> <Plug>ToggleBackground
" imap <unique> <F12> <Plug>ToggleBackground
" vmap <unique> <F12> <Plug>ToggleBackground
