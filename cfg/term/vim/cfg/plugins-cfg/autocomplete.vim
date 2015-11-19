if neobundle#tap('deoplete.nvim') && has('nvim') "{{{
  let g:deoplete#enable_at_startup = 1
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/deoplete.vim'
  call neobundle#untap()
endif "}}}


if neobundle#tap('neocomplete.vim') && has('lua') && !has('nvim') "{{{
  let g:neocomplete#enable_at_startup = 1
  noremap <unique> <Leader>tN :<C-u>NeoCompleteToggle<CR>
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/neocomplete.vim'
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


if neobundle#tap('syntastic')  "{{{
  noremap <unique> <Leader>tx :<C-u>SyntasticToggleMode<CR>
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/syntastic.vim'
  call neobundle#untap()
endif "}}}
