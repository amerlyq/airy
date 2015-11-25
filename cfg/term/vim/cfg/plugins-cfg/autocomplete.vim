if neobundle#tap('syntastic')  "{{{
  noremap <unique> [Toggle]x :<C-u>SyntasticToggleMode<CR>
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/syntastic.vim'
  call neobundle#untap()
endif "}}}


if neobundle#tap('neocomplete.vim') && has('lua') && !has('nvim') "{{{
  let g:neocomplete#enable_at_startup = 1
  noremap <unique> [Toggle]N :<C-u>NeoCompleteToggle<CR>
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/neocomplete.vim'
  call neobundle#untap()
endif "}}}


if neobundle#tap('deoplete.nvim') && has('nvim') "{{{
  let g:deoplete#enable_at_startup = 1
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/deoplete.vim'
  call neobundle#untap()
endif "}}}


if neobundle#tap('neopairs.vim')  "{{{
  let g:neopairs#enable = 1
  fun! neobundle#hooks.on_post_source(bundle)
    let g:neopairs#pairs = g:neopairs#_pairs
  endf
  call neobundle#untap()
endif "}}}


if neobundle#tap('echodoc.vim')  "{{{
  " set cmdheight=2
  let g:echodoc_enable_at_startup = 1
  call neobundle#untap()
endif "}}}


if neobundle#tap('neosnippet.vim')  "{{{
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/neosnippet.vim'
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-marching')  "{{{
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/vim-marching.vim'
  call neobundle#untap()
endif "}}}


if neobundle#tap('clang_complete')  "{{{
  let g:clang_complete_auto = 0
  let g:clang_auto_select = 0
  let g:clang_default_keymappings = 0
  "let g:clang_use_library = 1
  call neobundle#untap()
endif "}}}
