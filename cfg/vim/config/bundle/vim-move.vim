" The move plugin is used to move lines and visual selections up and down by
" wrapping the :move command.

" Activate it again here and in plugins, when fix Meta-Esc problem with terminal
" let g:move_map_keys = 0
" let g:move_key_modifier = 'M'
let g:move_auto_indent = 1

" Move selected block down by one line.
" nmap <A-j> <Plug>MoveLineDown
" nmap <A-k> <Plug>MoveLineUp
" vmap <A-j> <Plug>MoveBlockDown
" vmap <A-k> <Plug>MoveBlockUp

" Move selected block down by half a page size.
" <Plug>MoveBlockHalfPageDown
" <Plug>MoveBlockHalfPageUp
" <Plug>MoveLineHalfPageDown
" <Plug>MoveLineHalfPageUp
