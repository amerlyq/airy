if neobundle#tap('vim-airline') "{{{
  "" VISUAL
  let g:airline_powerline_fonts = 1
  if !exists('g:airline_symbols')
    " Also use it when font have no support for Powerline
    let g:airline_symbols = {}
  endif

  " Use only necessary plugins
  let g:airline#extensions#disable_rtp_load = 1
  let g:airline#extensions#whitespace#enabled = 0
  " POSSIBLE: 'branch', 'tmuxline', 'windowswap', 'virtualenv',
  " DISABLED: 'nrrwrgn' (conflict with lazy-loading), 'tagbar' (slow)
  " let g:airline_extensions = [ 'tabline', 'hunks', 'syntastic' ]
  let g:airline_extensions = []

  "" TABS and BUFFERS
  let g:airline#extensions#tabline#show_tabs = 0
  let g:airline#extensions#tabline#buffer_min_count = 2
  let g:airline#extensions#tabline#show_buffers = 1
  let g:airline#extensions#tabline#tab_nr_type = 2
  " let g:airline#extensions#tabline#show_tab_nr = 1
  " let g:airline#extensions#tabline#show_tab_type = 1
  " let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
  let g:airline#extensions#tabline#buffer_idx_mode = 1


  " Direct pick buffer on <leader>\d
  for i in range(1,9)
    call Map_nxo('[Frame]'.i, '<Plug>AirlineSelectTab'.i, 'n')
  endfor


  "" GIT signify + fugitive
  ""Maybe it will reduce CPU load, not showing which lines are chaged
  "(gitgutter, signify, etc)
  " let g:airline#extensions#hunks#enabled=0

  call neobundle#untap()
endif "}}}
