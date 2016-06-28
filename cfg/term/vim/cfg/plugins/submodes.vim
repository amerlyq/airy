""" Submodes

"" (DISABLED) Dependency of user modes with custom temporary remappings {{{1
" ALT:USE: <Plug>(submode-
call dein#add('kana/vim-submode', {'if': 0, 'lazy': 0,
  \ 'on_func': 'submode#',
  \ 'on_map': '[[n, x]]',
  \ 'on_cmd': 'SubmodeRestoreOptions',
  \ 'hook_source': 'source $DEINHOOKS/submodes-define.vim'})
