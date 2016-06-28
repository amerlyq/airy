""" Actions

"" Dependency of support to '.' on <Plug> mappings {{{1
call dein#add('tpope/vim-repeat')



"" CHECK: Transforms various languages oneline <--> block constructions {{{1
call dein#add('AndrewRadev/splitjoin.vim', {
  \ 'on_map': [['n', '<Plug>Splitjoin']],
  \ 'hook_source': "
\\n   let g:splitjoin_split_mapping = ''
\\n   let g:splitjoin_join_mapping = ''
\"})

if dein#tap('splitjoin.vim')
  nmap <unique><silent> [Space]j <Plug>SplitjoinJoin<CR>
  nmap <unique><silent> [Space]k <Plug>SplitjoinSplit<CR>
endif



"" Use CTRL-A/X to increment dates, times, and more {{{1
" STD: <Plug>SpeedDating
call dein#add('tpope/vim-speeddating', {
  \ 'on_map': [['nx', '<C-a>', '<C-x>'], ['n', 'd<C-a>', 'd<C-x>']],
  \ 'depends': 'vim-repeat'})



"" On insert in VISUAL mode behave like as V-BLOCK {{{1
" STD: <Plug>(niceblock-
call dein#add('kana/vim-niceblock', {
  \ 'on_map': [['x', 'A', 'I', 'gI']]})



"" Expand/shrink current visual selection {{{1
call dein#add('terryma/vim-expand-region', {
  \ 'on_map': [['nx', '<Plug>(expand_region_']]})

if dein#tap('vim-expand-region')
  call Map_nxo('+', '<Plug>(expand_region_expand)', 'nx')
  call Map_nxo('-', '<Plug>(expand_region_shrink)', 'nx')
endif
