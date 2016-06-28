""" Statusline && colorschemes
" EXPL: always load/show from the start

"" Fast bottom/top status panels w/ integration {{{1
call dein#add('vim-airline/vim-airline-themes')
call dein#add('bling/vim-airline', {
  \ 'depends': 'vim-airline-themes',
  \ 'hook_add': 'source $DEINHOOKS/airline.vim'})

if dein#tap('vim-airline')
  for i in range(1,9)  " Directly pick buffer on [Frame]\d
    call Map_nxo('[Frame]'.i, '<Plug>AirlineSelectTab'.i, 'n')
  endfor
endif "}}}



" Cursor line number inherits color from airline mode color {{{1
" TRY? interesting, but too distractive from cursor
" call dein#add('ntpeters/vim-airline-colornum')



"" Sticked to this colorscheme 2+ years already... {{{1
" ALT:(both) https://github.com/Samuel-Phillips/nvim-colors-solarized
" DEV: simplified solarized -- with menu/etc removed
"   -- possibly with re-defined colors for nou.vim?
" CHECK: maybe 'if' is insufficient -- need activate both, and disable one?
call dein#add('altercation/vim-colors-solarized', {
  \ 'if': '!has("nvim") || !exists("$NVIM_TUI_ENABLE_TRUE_COLOR")',
  \ 'hook_add': 'source $DEINHOOKS/solarized.vim'})

"" Fork which supports term TRUE_COLOR {{{1
call dein#add('frankier/neovim-colors-solarized-truecolor-only', {
  \ 'if': 'has("nvim") && exists("$NVIM_TUI_ENABLE_TRUE_COLOR")',
  \ 'hook_add': 'source $DEINHOOKS/solarized.vim'})



"" Alternative nice dark colorscheme {{{1
call dein#add('tomasr/molokai')
