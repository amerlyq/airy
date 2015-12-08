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
  " Mappings inside widget
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
  " OR: TagbarOpenAutoClose,
  " ALSO:SEE: TagbarTogglePause, TagbarShowTag
  let g:tagbar_width = 30
  let g:tagbar_zoomwidth = 0  " show longest visible tag, =<N> for fixed
  let g:tagbar_autoclose = 1
  " let g:tagbar_autofocus = 1
  let g:tagbar_sort = 0  " Sort manually on 's'
  let g:tagbar_compact = 1
  let g:tagbar_indent = 2
  " let g:tagbar_foldlevel = 2
  let g:tagbar_autopreview = 1
  call neobundle#untap()
endif "}}}


if neobundle#tap('linediff.vim') "{{{
  nnoremap <unique> [Frame]l  :LinediffReset<CR>
  vnoremap <unique> [Frame]l  :Linediff<CR>
  call neobundle#untap()
endif "}}}


if neobundle#tap('NrrwRgn') "{{{
  " let g:nrrw_rgn_nohl = 1
  " let g:nrrw_rgn_hl = 'Search'
  let g:nrrw_topbot_leftright = 'botright'
  " let g:nrrw_rgn_protect = 'n'  " Disable nowrite on original buffer
  "" Update cursor pos in original on move in nrrwrng
  " let g:nrrw_rgn_update_orig_win = 1
  "" Do commands on create/close
  " let b:nrrw_aucmd_create = "set ft=csv|%ArrangeCol"
  " let b:nrrw_aucmd_close  = "%UnArrangeColumn"
  " let b:nrrw_aucmd_written = ':update'

  " BUG: don't work as expected? What it must to do at all?
  "USAGE:HACK: Change filetype for opened region ':NN awk'
  " command! -nargs=* -bang -range -complete=filetype NN
  "     \ :<line1>,<line2> call nrrwrgn#NrrwRgn('',<q-bang>)
  "     \ | setl filetype=<args>

  "USAGE:HACK: Filter by pattern and open in split
  "NOTE: hide comments (temporary strip) by ':v/^#/NRP'
  let s:subs = {
  \ 'n' : 'g//NRP<CR>:NRM<CR>',
  \ 'N' : 'v//NRP<CR>:NRM<CR>',
  \}
  for [c, r] in items(s:subs) | for m in ['n','x']
    exe m.'noremap <silent><unique> [Frame]'.c.' :'.(m=='n'?'%':'').r
  endfor| endfor

  " Operator to select region in split 'n', or in current buffer
  for [c, op] in items({'n': 'Do', 'N': 'BangDo'})
    call Map_nxo('<Leader>'.c, '<Plug>Nrrwrgn'.op)
  endfor
  call neobundle#untap()
endif "}}}
