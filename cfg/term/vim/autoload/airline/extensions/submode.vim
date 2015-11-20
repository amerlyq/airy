" vim: et ts=2 sts=2 sw=2
" @copyright (c) Dmytro Kolomoiets (amerlyq), 2015: MIT License
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
  let w:airline_section_b = get(w:, 'airline_section_b', g:airline_section_b)
  if w:airline_section_b != ''
    let w:airline_section_b .= s:spc . g:airline_left_alt_sep . s:spc
  endif
  let w:airline_section_b .= '%{airline#extensions#submode#get()}'
endfunction

function! airline#extensions#submode#get()
  let l:nm = submode#current()
  return (l:nm != '') ? g:airline#extensions#submode#prefix.l:nm : l:nm
endfunction
