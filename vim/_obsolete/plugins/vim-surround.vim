if neobundle#tap('vim-surround')  "{{{1
  let g:surround_no_mappings=1

  " Existing: operator-pending analogue (HACK)
  nmap <unique> dq <Plug>Dsurround
  nmap <unique> cq <Plug>Csurround
  " New: add on same line
  nmap <unique> yq <Plug>Ysurround
  xmap <unique>  q <Plug>VSurround
  " New: surround on new lines
  nmap <unique> yQ <Plug>YSurround
  xmap <unique>  Q <Plug>VgSurround
  " New: use whole line
  nmap <unique>  Q <Plug>Yssurround
  nmap <unique> gQ <Plug>YSsurround

  " gs, <C-G>s, <C-G>S -- I can use for my aims!!
  " <Plug>Isurround -- unused

  if !hasmapto("<Plug>Isurround","i") && "" == mapcheck("<C-S>","i")
    imap <C-S> <Plug>Isurround
  endif
endif

