""" Operators

"" Dependency of 'vim-operator-*' and vim-clang-format {{{1
" BUG: not loads from inside 'ag.vim/plugin/' by lazy 'on_func'
call dein#add('kana/vim-operator-user', {'lazy': 0,
  \ 'on_func': 'operator#user#define'})



"" Manage surrounding block pairs ({[&quot'` over the motion {{{1
" BUG: first surround on alias is wrong: veq2
" ALT: (TODO: compare code) https://github.com/machakann/vim-sandwich
" CHG mappings: [[nx, q[adr]], [n, q[bBfFQ], q[({[&quot'<`] ]
" DEPRECATED:
"   - (bloated) tpope/vim-surround
call dein#add('rhysd/vim-operator-surround', {
  \ 'on_map': [['nx', '<Plug>']],
  \ 'depends': 'vim-operator-user',
  \ 'hook_source': 'source $DEINHOOKS/surround.src.vim',
  \ 'hook_add': 'source $DEINHOOKS/surround.add.vim'})



"" (DISABLED) Allows direct char appends after surround {{{1
" - For VISUAL (where I use append the most), original plugin is convenient
" - THINK:ADD: direct operators for NORMAL?
" 'osyo-manga/vim-operator-surround-before', {'if': 0,
"   on_map: [[nx, <Plug>(operator-surround-append-before]]
"   depends: ['vim-operator-user', 'vim-operator-surround']



"" Run a command and show its result quickly. {{{1
call dein#add('thinca/vim-quickrun', {
  \ 'on_map': {'n': '<Plug>'},
  \ 'on_cmd': 'QuickRun',
  \ 'hook_add': 'nmap <silent> [Space]r <Plug>(quickrun)'})



"" CHECK open URI or search. Combinable with vim-quickrun ? {{{1
call dein#add('tyru/open-browser.vim', {
  \ 'hook_add': "
\\n   nmap gx <Plug>(openbrowser-smart-search)
\\n   vmap gx <Plug>(openbrowser-smart-search)
\"})



"" Replaces motion by register content {{{1
" CHG mappings: [[nxo, gr]]
call dein#add('kana/vim-operator-replace', {
  \ 'on_map': [['nx', '<Plug>']],
  \ 'depends': 'vim-operator-user'})

if dein#tap('vim-operator-replace')
  " THINK Could be used instead of my own paste-replace?
  nmap <silent><unique> gr <Plug>(operator-replace)
  xmap <silent><unique> gr <Plug>(operator-replace)
  nmap <silent><unique> gR <Plug>(operator-replace)$
  xmap <silent><unique> gR <Plug>(operator-replace)$
endif



"" Exchange text: cx{motion} on first, then cx{motion} on other. {{{1
" USAGE: line 'cxc' and clear 'cxx', as 'cxc' is more comfortable
" CHG : [[x, X], [n, cx, cxc, cxx]]
call dein#add('tommcdo/vim-exchange', {
  \ 'on_map': [['nx', '<Plug>(Exchange']]})

if dein#tap('vim-exchange')
  xmap <silent><unique> X   <Plug>(Exchange)
  nmap <silent><unique> cx  <Plug>(Exchange)
  nmap <silent><unique> cxc <Plug>(ExchangeLine)
  nmap <silent><unique> cxx <Plug>(ExchangeClear)
endif



"" Toggle commentstring, ADD textobj-comment {{{1
" DEPRECATED: - (overladen) 'tomtom/tcomment_vim'
call dein#add('tpope/vim-commentary', {
  \ 'on_map': ['gc', ['n', 'gcc', 'cgc', 'gcu']],
  \ 'on_cmd': 'Commentary'})

" ALT: 'tyru/caw.vim', on_map = {nx = '<Plug>'}, hook_add = '''
"   function! InitCaw() abort
"     if !&l:modifiable
"       silent! nunmap <buffer> gc
"       silent! xunmap <buffer> gc
"       silent! nunmap <buffer> gcc
"       silent! xunmap <buffer> gcc
"     else
"       nmap <buffer> gc <Plug>(caw:prefix)
"       xmap <buffer> gc <Plug>(caw:prefix)
"       nmap <buffer> gcc <Plug>(caw:hatpos:toggle)
"       xmap <buffer> gcc <Plug>(caw:hatpos:toggle)
"     endif
"   endfunction
"   autocmd MyAutoCmd FileType * call InitCaw()
" '''



"" Shift/jump func-args/list-item/table-cell, ADD textobj-args {{{1
" ALT:TODO:SEE:
"   - sgur/vim-textobj-parameter
"   - PeterRincker/vim-argumentative
" CHG mappings: [[xo, aa, ia], [n, ga, gA, '[a', ']a']]
call dein#add('AndrewRadev/sideways.vim', {
  \ 'on_map': '<Plug>Sideways',
  \ 'on_cmd': ['SidewaysLeft', 'SidewaysRight', 'SidewaysJumpLeft', 'SidewaysJumpRight'],
  \ 'depends': 'vim-repeat'})

if dein#tap('sideways.vim')
  xmap <silent><unique> aa <Plug>SidewaysArgumentTextobjA
  omap <silent><unique> aa <Plug>SidewaysArgumentTextobjA
  xmap <silent><unique> ia <Plug>SidewaysArgumentTextobjI
  omap <silent><unique> ia <Plug>SidewaysArgumentTextobjI
  " NOTE: overrides 'ga -- print ascii for letter', do 'norm! ga' on demand
  nmap <silent><unique> ga <Plug>SidewaysLeft
  nmap <silent><unique> gA <Plug>SidewaysRight
  " TODO replace with ',a' OR '<Tab>a', and move Ag to '[Frame]a]'
  noremap <silent><unique> [a :<C-u>SidewaysJumpLeft<CR>
  noremap <silent><unique> ]a :<C-u>SidewaysJumpRight<CR>
endif
