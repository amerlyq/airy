" vim:ts=2:sts=2:sw=2
" @copyright: Dmytro Kolomoiets (amerlyq), 2015
" @license: MIT
" @refs: https://github.com/kana/vim-submodule

if !exists('*submode#current') | finish | endif

let s:spc = g:airline_symbols.space
if !exists('g:airline#extensions#submode#prefix')
  let g:airline#extensions#submode#prefix = "\u223b" "'M:'
endif


function! airline#extensions#submode#init(ext)
  call airline#parts#define_raw('submode', '%{airline#extensions#submode#get()}')
  call a:ext.add_statusline_func('airline#extensions#submode#apply')
endfunction

function! airline#extensions#submode#apply(...)
  let w:airline_section_a = get(w:, 'airline_section_a', g:airline_section_a)
  let w:airline_section_a .= '%{airline#extensions#submode#get()}'
endfunction

function! airline#extensions#submode#get()
  let l:nm = submode#current()
  ". g:airline_left_alt_sep
  return (l:nm == '') ? l:nm : s:spc.s:spc.
        \ g:airline#extensions#submode#prefix .s:spc. l:nm
endfunction
