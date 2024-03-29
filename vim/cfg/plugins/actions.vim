""" Actions

"" Dependency of support to '.' on <Plug> mappings {{{1
call dein#add('tpope/vim-repeat')



"" Use CTRL-A/X to increment dates, times, and more {{{1
" FIXED:BAD: d<C-..> overlaps with 'ag_grp' shortcut 'd'
" FIXME:BAD: <C-x> overlaps with unicode.vim '<C-x><C-..>'
" TRY:(nou.vim) shorter year in date
"   => hook_post_source: SpeedDatingFormat %y-%m-%d
" BAD: can't restore visual selection after <C-a>
" xnoremap <silent> <Plug>(speeddating+) :<C-u>call speeddating#incrementvisual(v:count1)<Bar>exe 'norm!`['.strpart(getregtype(),0,1).'`]'<CR>
call dein#add('tpope/vim-speeddating', {
  \ 'on_map': [['nx', '<Plug>SpeedDating']],
  \ 'on_func': 'speeddating#',
  \ 'depends': 'vim-repeat',
  \ 'hook_source': "
\\n   let g:speeddating_no_mappings = 1
\\n   nnoremap <Plug>SpeedDatingFallbackUp <C-a>
\\n   nnoremap <Plug>SpeedDatingFallbackDown <C-x>
\", 'hook_add': "
\\n   call Map_nxo('<C-a>', '<Plug>SpeedDatingUp',  'nx', 1)
\\n   call Map_nxo('<C-x>', '<Plug>SpeedDatingDown','nx', 1)
\"})



"" Change textobj and propagate through the buffer {{{1
" ALT: 'haya14busa/vim-asterisk' + 'osyo-manga/vim-over'
call dein#add('AndrewRadev/multichange.vim', {
  \ 'on_cmd': 'Multichange',
  \ 'on_map': [['n', '[Frame]m']],
  \ 'hook_source': "
\\n   let g:multichange_mapping = '[Frame]m'
\\n   let g:multichange_motion_mapping = 'm'
\"})



"" CHECK: Transforms various languages oneline <--> block constructions {{{1
" ALT: osyo-manga/vim-jplus
" BAD: don't work with lazy loading
" BAD: lazy dein can't reuse any already mapped keys like 'J/K'
" BAD: fallback only to builtin 'J/K', ignoring user keymaps
call dein#add('AndrewRadev/splitjoin.vim', {'lazy': 0,
  \ 'on_cmd': ['SplitjoinJoin', 'SplitjoinSplit'],
  \ 'on_map': [['n', '[Frame]j', '[Frame]k']],
  \ 'hook_add': "
\\n   let g:splitjoin_join_mapping = '[Frame]j'
\\n   let g:splitjoin_split_mapping = '[Frame]k'
\"})
" 'hook_post_source': 'sil! exe "do FileType" &ft',
" \\n   nnoremap <unique><silent> [Frame]j :SplitjoinJoin<CR>
" \\n   nnoremap <unique><silent> [Frame]k :SplitjoinSplit<CR>



"" Change textobj and propagate through the buffer {{{1
" SEE: g:switch_definitions, {b|g}:switch_custom_definitions
" \ 'rev': 'execute-functions',
call dein#add('AndrewRadev/switch.vim', {
  \ 'on_func': 'switch#',
  \ 'on_cmd': ['Switch', 'SwitchReverse'],
  \ 'on_map': [['nx', '<CR>', '<BS>']],
  \ 'hook_source': _hcat('switch.src'),
  \})
"" DISABLED: incrementing date conflicts with switching date <-> xtref
"   \ 'hook_add': "
" \\n   nnoremap <silent> <Plug>(switch+date) :<C-u>if !switch#Switch()<Bar> call speeddating#increment(v:count1) <Bar>en<CR>
" \\n   nnoremap <silent> <Plug>(switch-date) :<C-u>if !switch#Switch({'reverse': 1})<Bar> call speeddating#increment(-v:count1) <Bar>en<CR>
" \\n   call Map_nxo('<C-a>', '<Plug>(switch+date)', 'n', 2)
" \\n   call Map_nxo('<C-x>', '<Plug>(switch-date)', 'n', 2)
" \"})



"" On insert in VISUAL mode behave like as V-BLOCK {{{1
" STD: <Plug>(niceblock-
call dein#add('kana/vim-niceblock', {
  \ 'on_map': [['x', 'A', 'I', 'gI']]})



"" Expand/shrink current visual selection {{{1
call dein#add('terryma/vim-expand-region', {
  \ 'on_map': [['x', '<Plug>(expand_region_']],
  \ 'hook_add': "
\\n   call Map_nxo('+', '<Plug>(expand_region_expand)', 'x')
\\n   call Map_nxo('-', '<Plug>(expand_region_shrink)', 'x')
\"})



""" Selections -- mark and retrieve (save/load) {{{1
" BAD: seems like can't be remapped because of <script> param in mapping
" call dein#add('iago-lito/vim-visualMarks', {'lazy': 0}}


"" FAIL: broken code / exception on load
"" (DISABLED) Dependency of user modes with custom temporary remappings {{{1
" ALT:USE: <Plug>(submode-
" call dein#add('kana/vim-submode', {'if': 0, 'lazy': 0,
"   \ 'on_func': 'submode#',
"   \ 'on_map': '[[n, x]]',
"   \ 'on_cmd': 'SubmodeRestoreOptions',
"   \ 'hook_source': _hcat('submodes-define')})
