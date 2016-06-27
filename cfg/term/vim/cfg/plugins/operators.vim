""" Operators

"" Dependency of 'vim-operator-*' and vim-clang-format
" BUG: not loads from inside 'ag.vim/plugin/' by lazy 'on_func'
call dein#add('kana/vim-operator-user', {'lazy': 0,
  \ 'on_func': 'operator#user#define'})


"" Manage surrounding block pairs ({[&quot'` over the motion
" ALT: (TODO: compare code) https://github.com/machakann/vim-sandwich
" CHG mappings: [[nx, q[adr]], [n, q[bBfFQ], q[({[&quot'<`] ]
" NOTE: last 3 deps -- for chained mappings (Optional) -- in textobj.vim
call dein#add('rhysd/vim-operator-surround', {
  \ 'on_map': [['nx', '<Plug>']],
  \ 'depends': [
  \   'kana/vim-operator-user',
  \   'thinca/vim-textobj-between',
  \   'beloglazov/vim-textobj-quotes',
  \   'rhysd/vim-textobj-anyblock',
  \ ]})
" DEPRECATED:
"   - (bloated) tpope/vim-surround


"" (DISABLED) Allows direct char appends after surround
" - For VISUAL (where I use append the most), original plugin is convenient
" - THINK:ADD: direct operators for NORMAL?
" 'osyo-manga/vim-operator-surround-before', {'if': 0,
"   on_map: [[nx, <Plug>(operator-surround-append-before]]
"   depends: ['kana/vim-operator-user', 'rhysd/vim-operator-surround']


"" Replaces motion by register content
" CHG mappings: [[nxo, gr]]
call dein#add('kana/vim-operator-replace', {
  \ 'on_map': [['nx', '<Plug>']]
  \ 'depends': 'kana/vim-operator-user'})


"" Exchange text: cx{motion} on first, then cx{motion} on other.
" USAGE: line 'cxc' and clear 'cxx', as 'cxc' is more comfortable
" CHG : [[x, X], [n, cx, cxc, cxx]]
call dein#add('tommcdo/vim-exchange', {
  \ 'on_map': [['nx', '<Plug>(Exchange']]})


"" Toggle commentstring, ADD textobj-comment
call dein#add('tpope/vim-commentary', {
  \ 'on_map': ['gc', ['n', 'gcc', 'cgc', 'gcu']],
  \ 'on_cmd': 'Commentary'})
" DEPRECATED: - (overladen) 'tomtom/tcomment_vim'


"" Shift/jump func-args/list-item/table-cell, ADD textobj-args
" ALT:TODO:SEE:
"   - sgur/vim-textobj-parameter
"   - PeterRincker/vim-argumentative
" CHG mappings: [[xo, aa, ia], [n, ga, gA, '[a', ']a']]
call dein#add('AndrewRadev/sideways.vim', {
  \ 'on_map': '<Plug>Sideways'
  \ 'on_cmd': ['SidewaysLeft', 'SidewaysRight', 'SidewaysJumpLeft', 'SidewaysJumpRight']
  \ 'depends': 'tpope/vim-repeat'})


"" Auto-formatter for c/cpp/obj-c
call dein#add('rhysd/vim-clang-format', {
  \ 'if': 'executable("clang-format")',
  \ 'on_map': '<Plug>(operator-clang-format)',
  \ 'on_cmd': ['ClangFormat', 'ClangFormatEchoFormattedCode'],
  \ 'on_ft': ['c', 'cpp', 'objc'],
  \ 'depends': ['kana/vim-operator-user', 'Shougo/vimproc.vim']})


"" (DISABLED) Autoformatting with one button, can use custom (like clang-styler)
" ATTENTION: Not operator, but placed near to 'vim-clang-format'
" 'if': 'executable("clang-format")||executable("astyle")||executable("tidy")',
call dein#add('Chiel92/vim-autoformat', {'if': 0,
  \ 'on_cmd': ['Autoformat', 'NextFormatter', 'NextFormatter']})
