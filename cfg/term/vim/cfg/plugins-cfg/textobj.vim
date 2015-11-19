"{{{1 Textobj ============================
if neobundle#tap('vim-textobj-entire')  "{{{
  let g:textobj_entire_no_default_key_mappings = 1
  xmap <silent><unique> aG <Plug>(textobj-entire-a)
  omap <silent><unique> aG <Plug>(textobj-entire-a)
  xmap <silent><unique> iG <Plug>(textobj-entire-i)
  omap <silent><unique> iG <Plug>(textobj-entire-i)
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-textobj-function')  "{{{
  let g:textobj_function_no_default_key_mappings = 1
  xmap <silent><unique> aF  <Plug>(textobj-function-a)
  omap <silent><unique> aF  <Plug>(textobj-function-a)
  xmap <silent><unique> iF  <Plug>(textobj-function-i)
  omap <silent><unique> iF  <Plug>(textobj-function-i)
  xmap <silent><unique> agf <Plug>(textobj-function-A)
  omap <silent><unique> agf <Plug>(textobj-function-A)
  xmap <silent><unique> igf <Plug>(textobj-function-I)
  omap <silent><unique> igf <Plug>(textobj-function-I)
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-textobj-sigil')  "{{{
  let g:textobj_sigil_no_default_key_mappings = 1
  xmap <silent><unique> ad <Plug>(textobj-sigil-a)
  omap <silent><unique> ad <Plug>(textobj-sigil-a)
  xmap <silent><unique> id <Plug>(textobj-sigil-i)
  omap <silent><unique> id <Plug>(textobj-sigil-i)
  call neobundle#untap()
endif "}}}


" TODO: maybe space/sigil change mappings to reverse -- G/Q?
if neobundle#tap('vim-textobj-space')  "{{{
  let g:textobj_space_no_default_key_mappings = 1
  xmap <silent><unique> as <Plug>(textobj-space-a)
  omap <silent><unique> as <Plug>(textobj-space-a)
  xmap <silent><unique> is <Plug>(textobj-space-i)
  omap <silent><unique> is <Plug>(textobj-space-i)
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-textobj-syntax')  "{{{
  let g:textobj_syntax_no_default_key_mappings = 1
  " ATTENTION currently textobj-syntax-a acts the same as textobj-syntax-i
  xmap <silent><unique> ah <Plug>(textobj-syntax-a)
  omap <silent><unique> ah <Plug>(textobj-syntax-a)
  xmap <silent><unique> ih <Plug>(textobj-syntax-i)
  omap <silent><unique> ih <Plug>(textobj-syntax-i)
  call neobundle#untap()
endif "}}}
