""" Actions

"" Dependency of support to '.' on <Plug> mappings {{{1
call dein#add('tpope/vim-repeat')



"" Selects a column of identical characters {{{1
" Can also be used as a text object for an operator
" On one-line vsel selects a block of identical columns.
call dein#add('ngn/vim-column', {
  \ 'on_map': '<Bar>'})



"" CHECK: Transforms various languages oneline <--> block constructions {{{1
" ALT: osyo-manga/vim-jplus
call dein#add('AndrewRadev/splitjoin.vim', {
  \ 'on_map': [['n', '<Plug>Splitjoin']],
  \ 'hook_source': "
\\n   let g:splitjoin_split_mapping = ''
\\n   let g:splitjoin_join_mapping = ''
\", 'hook_add': "
\\n   nmap <unique><silent> [Space]j <Plug>SplitjoinJoin<CR>
\\n   nmap <unique><silent> [Space]k <Plug>SplitjoinSplit<CR>
\"})



"" Use CTRL-A/X to increment dates, times, and more {{{1
" FIXED:BAD: d<C-..> overlaps with 'ag_grp' shortcut 'd'
" FIXME:BAD: <C-x> overlaps with unicode.vim '<C-x><C-..>'
" TRY:(nou.vim) shorter year in date
"   => hook_post_source: SpeedDatingFormat %y-%m-%d
call dein#add('tpope/vim-speeddating', {
  \ 'on_map': [['nx', '<Plug>SpeedDating']],
  \ 'depends': 'vim-repeat',
  \ 'hook_add': "
\\n   let g:speeddating_no_mappings = 1
\\n   call Map_nxo('<C-a>', '<Plug>SpeedDatingUp',   'nx')
\\n   call Map_nxo('<C-x>', '<Plug>SpeedDatingDown', 'nx')
\"})



"" On insert in VISUAL mode behave like as V-BLOCK {{{1
" STD: <Plug>(niceblock-
call dein#add('kana/vim-niceblock', {
  \ 'on_map': [['x', 'A', 'I', 'gI']]})



"" Expand/shrink current visual selection {{{1
call dein#add('terryma/vim-expand-region', {
  \ 'on_map': [['nx', '<Plug>(expand_region_']],
  \ 'hook_add': "
\\n   call Map_nxo('+', '<Plug>(expand_region_expand)', 'nx')
\\n   call Map_nxo('-', '<Plug>(expand_region_shrink)', 'nx')
\"})



"" (DISABLED) Dependency of user modes with custom temporary remappings {{{1
" ALT:USE: <Plug>(submode-
call dein#add('kana/vim-submode', {'if': 0, 'lazy': 0,
  \ 'on_func': 'submode#',
  \ 'on_map': '[[n, x]]',
  \ 'on_cmd': 'SubmodeRestoreOptions',
  \ 'hook_source': _hcat('submodes-define')})
