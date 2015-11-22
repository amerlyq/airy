" Move to 'fun.vim'
if neobundle#tap('DrawIt') "{{{
  map <unique> [Unite]DI  <Plug>DrawItStart
  map <unique> [Unite]DS  <Plug>DrawItStop
  map <unique> [Unite]Dsw <Plug>SaveWinPosn
  map <unique> [Unite]Drw <Plug>RestoreWinPosn
  call neobundle#untap()
endif "}}}


if neobundle#tap('ListToggle') "{{{
    let g:lt_location_list_toggle_map = '[Unite]l'
    let g:lt_quickfix_list_toggle_map = '[Unite]q'
  call neobundle#untap()
endif "}}}


if neobundle#tap('undotree') "{{{
  nnoremap <silent><unique> [Unite]u  :UndotreeToggle<CR>
  let g:undotree_WindowLayout = 2
  let g:undotree_SetFocusWhenToggle = 1
  function g:Undotree_CustomMap()
    nmap <buffer> <Space> <Plug>UndotreeEnter
    nmap <buffer> d <Plug>UndotreeDiffToggle
    nmap <buffer> f <Plug>UndotreeFocusTarget
    nmap <buffer> J <Plug>UndotreeGoNextState
    nmap <buffer> K <Plug>UndotreeGoPreviousState
    nmap <buffer> t <Plug>UndotreeTimestampToggle
  endfunc
  call neobundle#untap()
endif "}}}


if neobundle#tap('tagbar') "{{{
  nnoremap <silent><unique> [Unite]t  :TagbarToggle<CR>
  call neobundle#untap()
endif "}}}


if neobundle#tap('linediff.vim') "{{{
  nnoremap <unique> [Frame]L  :LinediffReset<CR>
  vnoremap <unique> [Frame]L  :Linediff<CR>
  call neobundle#untap()
endif "}}}


if neobundle#tap('NrrwRgn') "{{{
  " let g:nrrw_rgn_nohl = 1
  let g:nrrw_topbot_leftright = 'botright'
  for [c, op] in items({'n': 'Do', 'N': 'BangDo'})
    call Map_nxo('[Frame]'.c, '<Plug>NrrwrgnBangDo'.op)
  endfor
  call neobundle#untap()
endif "}}}
