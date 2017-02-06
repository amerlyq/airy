if &cp||exists('g:loaded_xkb')|finish|else|let g:loaded_xkb=1|endif
" NOTE: you need to add 'xkb' module to airline for last insert indicator
" BUG:  insert mappings not working at all

call xkb#init()
