let g:airline_powerline_fonts = !(IsWindows() || IsAndroid())
if !exists('g:airline_symbols')
  let g:airline_symbols = {}  " USE when font not supporting Powerline
endif

" Use only necessary plugins
let g:airline#extensions#disable_rtp_load = 1
let g:airline_extensions = ['tabline', 'quickfix'] ", 'xkb' 'submode', 'unite'
" TRY: 'hunks', 'syntastic', 'undotree', 'promptline'
" POSSIBLE: 'branch', 'tmuxline', 'windowswap', 'virtualenv',
" DISABLED: 'nrrwrgn' (conflict with lazy-loading), 'tagbar' (slow)
" PLUG: 'anzu' (too inconspicuous)

"" TABS and BUFFERS
let g:airline#extensions#tabline#buffer_idx_mode = 1
let g:airline#extensions#tabline#show_tabs = 0  " always show buffers and nr tabs
let g:airline#extensions#tabline#show_buffers = 1
let g:airline#extensions#tabline#show_close_button = 1
let g:airline#extensions#tabline#tab_nr_type = 2
let g:airline#extensions#tabline#exclude_preview = 1
let g:airline#extensions#tabline#buffer_min_count = (argc()<2 ? 2 : 0)
" DISABLED: has priority over buffers
" let g:airline#extensions#tabline#tab_min_count = 2
let g:airline#extensions#tabline#formatter = 'unique_tail_improved'


" NOTE:(modified defaults): remove :term "!" prefix to show @/todo/!today buffer
let g:airline#extensions#tabline#ignore_bufadd_pat =
  \ 'defx|gundo|nerd_tree|startify|tagbar|term://|undotree|vimfiler'

"" GIT signify + fugitive, gitgutter, etc
""Maybe it will reduce CPU load, not showing which lines are chaged
" let g:airline#extensions#hunks#enabled=0
" let g:airline_exclude_preview = 1
