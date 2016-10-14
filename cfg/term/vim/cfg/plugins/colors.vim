""" Statusline && colorschemes
" EXPL: always load/show from the start

"" Fast bottom/top status panels w/ integration {{{1
" USE: Directly pick buffer on <M-1..9> OR [Frame]1..9
call dein#add('vim-airline/vim-airline-themes', {'lazy': 0})
call dein#add('bling/vim-airline', {
  \ 'on_event': 'VimEnter',
  \ 'depends': 'vim-airline-themes',
  \ 'hook_source': _hcat('airline.src'),
  \ 'hook_add': "
\\n   for i in range(1,9)
\\n     call Map_nxo('[Frame]'.i, '<Plug>AirlineSelectTab'.i, 'n')
\\n     call Map_nxo('<M-'.i.'>', '<Plug>AirlineSelectTab'.i, 'n')
\\n   endfor
\"})



" Cursor line number inherits color from airline mode color {{{1
" TRY? interesting, but too distractive from cursor
" call dein#add('ntpeters/vim-airline-colornum')



"" Sticked to this colorscheme 2+ years already... {{{1
" ALT:(both) https://github.com/Samuel-Phillips/nvim-colors-solarized
" DEV: simplified solarized -- with menu/etc removed
"   -- possibly with re-defined colors for nou.vim?
" CHECK: maybe 'if' is insufficient -- need activate both, and disable one?
"" Fork which supports term TRUE_COLOR
call dein#add('frankier/neovim-colors-solarized-truecolor-only', {
  \ 'if': 'has("nvim") && exists("$NVIM_TUI_ENABLE_TRUE_COLOR")',
  \ 'hook_add': _hcat('solarized.add')})

"" Original obsolete theme for old vim {{{
" ATTENTION: place after '...solarized-truecolor...'
call dein#add('altercation/vim-colors-solarized', {
  \ 'if': '!dein#tap("neovim-colors-solarized-truecolor-only")',
  \ 'hook_add': _hcat('solarized.add')})



"" Alternative nice dark colorscheme {{{1
call dein#add('tomasr/molokai')
" call dein#add('cocopon/iceberg.vim')
