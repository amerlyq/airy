" Move to 'fun.vim'
if neobundle#tap('DrawIt') "{{{
  map <unique> [Frame]DI  <Plug>DrawItStart
  map <unique> [Frame]DS  <Plug>DrawItStop
  map <unique> [Frame]Dsw <Plug>SaveWinPosn
  map <unique> [Frame]Drw <Plug>RestoreWinPosn
  call neobundle#untap()
endif "}}}


if neobundle#tap('ListToggle') "{{{
    let g:lt_location_list_toggle_map = '[Unite]l'
    let g:lt_quickfix_list_toggle_map = '[Unite]q'
  call neobundle#untap()
endif "}}}


if neobundle#tap('linediff.vim') "{{{
  nnoremap <unique> [Frame]L  :LinediffReset<CR>
  vnoremap <unique> [Frame]L  :Linediff<CR>
  call neobundle#untap()
endif "}}}


if neobundle#tap('NrrwRgn') "{{{
":: Focus on content in split window
  " Create two region buffers and use :diffthis --> instead of LineDiff
  " Multiselection in new buffer! :v/^#/NRP | NRM
  " Tip -- completely delete blocks you don't want to change.
  " let g:nrrw_rgn_nohl = 1
  " split buffer in same window
  let g:nrrw_topbot_leftright = 'botright'
  nmap <unique> <Leader>n <Plug>NrrwrgnDo
  xmap <unique> <Leader>n <Plug>NrrwrgnDo
  omap <unique> <Leader>n <Plug>NrrwrgnDo
  " separate buffer
  nmap <unique> <Leader>N <Plug>NrrwrgnBangDo
  xmap <unique> <Leader>N <Plug>NrrwrgnBangDo
  omap <unique> <Leader>N <Plug>NrrwrgnBangDo
  call neobundle#untap()
endif "}}}
