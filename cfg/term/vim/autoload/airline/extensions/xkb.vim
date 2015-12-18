" vim:ts=2:sts=2:sw=2
" @copyright: Dmytro Kolomoiets (amerlyq), 2015
" @license: MIT

if !exists('*xkb#show') | finish | endif

let s:spc = g:airline_symbols.space
if !exists('g:airline#extensions#xkb#prefix')
  let g:airline#extensions#xkb#prefix = '`'
endif


function! airline#extensions#xkb#init(ext)
  call airline#parts#define_raw('xkb', '%{airline#extensions#xkb#get()}')
  call a:ext.add_statusline_func('airline#extensions#xkb#apply')
endfunction

function! airline#extensions#xkb#apply(...)
  let w:airline_section_a = get(w:, 'airline_section_a', g:airline_section_a)
  let w:airline_section_a .= '%{airline#extensions#xkb#get()}'
endfunction

function! airline#extensions#xkb#get()
  let l:nm = xkb#show()  " s:spc.
  return (l:nm == '') ? l:nm : g:airline#extensions#xkb#prefix . l:nm
endfunction
