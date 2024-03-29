""" Operators

"" Dependency of 'vim-operator-*' and vim-clang-format {{{1
" BUG: not loads from inside 'ag.vim/plugin/' by lazy 'on_func'
call dein#add('kana/vim-operator-user', {'lazy': 0,
  \ 'on_func': 'operator#user#define'})



"" Manage surrounding block pairs ({[&quot'` over the motion {{{1
" BUG: first surround on alias is wrong: veq2 (last char not added)
" BUG: Impossible character to use as surround: qab\
" FIXME: don't exclude surrounding spaces when adding quotes
" ALT: (TODO: compare code) https://github.com/machakann/vim-sandwich
"   TALK: https://www.reddit.com/r/vim/comments/esrfno/why_vimsandwich_and_not_surroundvim/
"   CMP: https://joereynoldsaudio.com/2020/01/22/vim-sandwich-is-better-than-surround.html
" CHG mappings: [[nx, q[adr]], [n, q[bBfFQ], q[({[&quot'<`] ]
" DEPRECATED:
"   - (bloated) tpope/vim-surround
call dein#add('rhysd/vim-operator-surround', {
  \ 'on_map': [['nxo', '<Plug>']],
  \ 'depends': 'vim-operator-user',
  \ 'hook_source': _hcat('surround.src'),
  \ 'hook_add': _hcat('surround.add')})



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
  \ 'hook_add': "
\\n   nmap <silent> [Frame]r <Plug>(quickrun-op)
\\n   nmap <silent> [Frame]R <Plug>(quickrun)
\"})



"" Replaces motion by register content {{{1
" THINK Could be used instead of my own paste-replace?
call dein#add('kana/vim-operator-replace', {
  \ 'on_map': [['nx', '<Plug>']],
  \ 'depends': 'vim-operator-user',
  \ 'hook_add': "
\\n   nmap <silent><unique> gr <Plug>(operator-replace)
\\n   xmap <silent><unique> gr <Plug>(operator-replace)
\\n   nmap <silent><unique> gR <Plug>(operator-replace)$
\\n   xmap <silent><unique> gR <Plug>(operator-replace)$
\"})



"" Converts snake/camel case of joined words {{{1
" ALT: https://github.com/tpope/vim-abolish (SEE coersion -- 4 case converters)
call dein#add('tyru/operator-camelize.vim', {
  \ 'on_map': [['nxo', '<Plug>']],
  \ 'hook_add': "
\\n   map <silent><unique> <Leader>~  <Plug>(operator-camelize-toggle)
\"})



"" Exchange text: cx{motion} on first, then cx{motion} on other. {{{1
" ALT: https://github.com/osyo-manga/vim-operator-swap
" USAGE: line 'cxc' and clear 'cxx', as 'cxc' is more comfortable
" CHG : [[x, X], [n, cx, cxc, cxx]]
call dein#add('tommcdo/vim-exchange', {
  \ 'on_map': [['nx', '<Plug>(Exchange']],
  \ 'hook_add': "
\\n   xmap <silent><unique> X   <Plug>(Exchange)
\\n   nmap <silent><unique> cx  <Plug>(Exchange)
\\n   nmap <silent><unique> cxc <Plug>(ExchangeLine)
\\n   nmap <silent><unique> cxx <Plug>(ExchangeClear)
\"})



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

"" DEPR-by: TextYankPost※⡡⢨⠆⡲
" BAD:THINK: if plugin isn't installed -- 'y' won't work at all
" ALT:BET? https://github.com/machakann/vim-highlightedyank
" call dein#add('haya14busa/vim-operator-flashy', {
"   \ 'on_map': [['nxo', '<Plug>(operator-flashy)']],
"   \ 'depends': 'vim-operator-user',
"   \ 'hook_source': "
" \\n   hi! Flashy term=reverse cterm=reverse gui=reverse
" \\n   let g:operator#flashy#group = 'Flashy'
" \\n   let g:operator#flashy#flash_time = 130
" \", 'hook_add': "
" \\n    map <silent> y <Plug>(operator-flashy)
" \\n   nmap <silent> Y <Plug>(operator-flashy)$
" \\n   vmap <silent> Y $<Plug>(operator-flashy)
" \"})


"" Shift/jump func-args/list-item/table-cell, ADD textobj-args {{{1
" ALT:TODO:SEE:
"   - sgur/vim-textobj-parameter
"   - PeterRincker/vim-argumentative
" NOTE: overrides 'ga -- print ascii for letter', do 'norm! ga' on demand
" TODO replace [a ]a with ',a' OR '<Tab>a', and move Ag to '[Frame]a]'
" CHG mappings: [[xo, aa, ia], [n, ga, gA, '[a', ']a']]
call dein#add('AndrewRadev/sideways.vim', {
  \ 'on_map': [['nxo', '<Plug>Sideways']],
  \ 'on_cmd': 'Sideways*',
  \ 'depends': 'vim-repeat',
  \ 'hook_add': "
\\n   xmap <silent><unique> aa <Plug>SidewaysArgumentTextobjA
\\n   omap <silent><unique> aa <Plug>SidewaysArgumentTextobjA
\\n   xmap <silent><unique> ia <Plug>SidewaysArgumentTextobjI
\\n   omap <silent><unique> ia <Plug>SidewaysArgumentTextobjI
\\n
\\n   nmap <silent><unique> ga <Plug>SidewaysLeft
\\n   nmap <silent><unique> gA <Plug>SidewaysRight
\\n
\\n   noremap <silent><unique> [a :<C-u>SidewaysJumpLeft<CR>
\\n   noremap <silent><unique> ]a :<C-u>SidewaysJumpRight<CR>
\"})



""" Overlaps with AndrewRadev/sideways.vim
call dein#add('machakann/vim-swap', {
  \ 'on_map': [['nx', '<Plug>(swap-']],
  \ 'on_cmd': 'Sideways*',
  \ 'depends': 'vim-repeat',
  \ 'hook_add': "
\\n   let g:swap_no_default_key_mappings = 1
\\n   nmap <silent><unique> <Leader>< <Plug>(swap-prev)
\\n   nmap <silent><unique> <Leader>> <Plug>(swap-next)
\\n   nmap <silent><unique> <Leader>G <Plug>(swap-interactive)
\\n   xmap <silent><unique> <Leader>G <Plug>(swap-interactive)
\"})
