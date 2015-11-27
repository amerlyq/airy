"{{{1 Textobj ============================
if neobundle#tap('vim-textobj-delimited')  "{{{
  let g:textobj_delimited_no_default_key_mappings = 1
  call Map_textobj('_', 'delimited-forward')
  call Map_textobj('<Leader>_', 'delimited-backward')
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-textobj-function')  "{{{
  let g:textobj_function_no_default_key_mappings = 1
  call Map_textobj('gf', 'function')
  call Map_textobj('gF', 'function', 'toupper')
  call neobundle#untap()
endif "}}}


"{{{ Re-map bunch of textobj
" TODO: maybe space/sigil change mappings to reverse -- G/Q?
let s:maps = {'G': 'entire', 'd': 'sigil', 's': 'space', 'h': 'syntax'}
for [c, plug] in items(s:maps)
  if neobundle#tap('vim-textobj-'.plug)
    let g:textobj_{plug}_no_default_key_mappings = 1
    call Map_textobj(c, plug)
    call neobundle#untap()
  endif
endfor "}}}


if neobundle#tap('textobj-word-column.vim')  "{{{
  " Make word-columns more dumb, as they are too much «smart» for me
  " let g:textobj_word_column_no_smart_boundary_cols = 1
  call neobundle#untap()
endif "}}}
