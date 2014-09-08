let g:surround_no_mappings=1

nmap ds  <Plug>Dsurround
nmap cs  <Plug>Csurround
nmap ys  <Plug>Ysurround
nmap yS  <Plug>YSurround
nmap yss <Plug>Yssurround
nmap ySs <Plug>YSsurround
nmap ySS <Plug>YSsurround
xmap s   <Plug>VSurround
xmap S   <Plug>VgSurround

" gs, <C-G>s, <C-G>S -- I can use for my aims!!
" <Plug>Isurround -- unused

if !hasmapto("<Plug>Isurround","i") && "" == mapcheck("<C-S>","i")
  imap <C-S> <Plug>Isurround
endif
