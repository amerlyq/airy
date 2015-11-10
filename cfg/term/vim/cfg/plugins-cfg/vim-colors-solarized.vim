if !exists('solarized') | finish | endif

"If 256 -- will choose from existing palette similar colors:
"   makes brown bg and bold font...
" if &t_Co >= 88
"   let g:solarized_termcolors=256
" else
"   let g:solarized_termcolors=16
" endif

" Stich with normal! Them was wisely choosen.
" let g:solarized_contrast="high"    "default value is normal
" let g:solarized_visibility="high"    "default value is normal

let g:solarized_bold=1
let g:solarized_underline=1
let g:solarized_italic=1

" nmap <unique> <F12> <Plug>ToggleBackground
" imap <unique> <F12> <Plug>ToggleBackground
" vmap <unique> <F12> <Plug>ToggleBackground
