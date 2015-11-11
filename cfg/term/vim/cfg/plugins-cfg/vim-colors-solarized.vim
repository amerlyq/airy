"if !exists('solarized') | finish | endif

" Use solarized only with pre-setup palette!
if &term =~# '^rxvt'  "\|nvim
  let g:solarized_termcolors=16
else
"If 256 -- choose from existing palette similar colors:
"   makes brown bg and bold font...
  let g:solarized_termcolors=256
endif

" Stich with normal! Them was wisely choosen.
" let g:solarized_contrast="high"    "default value is normal
" let g:solarized_visibility="high"    "default value is normal

let g:solarized_bold=1
let g:solarized_underline=1
let g:solarized_italic=1

" nmap <unique> <F12> <Plug>ToggleBackground
" imap <unique> <F12> <Plug>ToggleBackground
" vmap <unique> <F12> <Plug>ToggleBackground
