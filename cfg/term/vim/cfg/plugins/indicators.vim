""" Indicators

"" Signs on changes and textobj on vcs-aware area {{{1
" ALT: airblade/vim-gitgutter: (git only, but much faster file save)
" EXPL: show from the start. Disable individually by ft.
" FIND:THINK: isn't :SignifyRefresh unnecessary?
" EXPL:(not lazy) so 'hook_source' can't be used
" NOTE: Textobj -- changed areas
"" Already mapped -- if busy: automaps <leader>gj and <leader>gk
call dein#add('mhinz/vim-signify', {'lazy': 0,
  \ 'on_map': [['xo', 'aS', 'iS'], ['n', '[c', ']c']],
  \ 'on_cmd': ['SignifyFold', 'SignifyToggle',
  \            'SignifyToggleHighlight', 'SignifyRefresh'],
  \ 'hook_add': _hcat('signify.add')})



"" Display, toggle and navigate by marks [a-zA-Z] and markers [0-9] {{{1
" ATTENTION: Lazy startup, press m<Esc> to load and show existing marks
" ALSO:USE: m, m. m- m/ m? dm  CHG: m<Del> m<BS>
" STD: :marks(list), m'`(prev), m<>(visual), m[](change/yank), :k[a-zA-Z'](mark)
" CHECK: IncludeMarkers >= 10 --> USE? \"
call dein#add('kshenoy/vim-signature', {
  \ 'on_map': [['n', "m", "']", "'[", "`]", "`[", "]'", "['",
  \             "]`", "[`", "]-", "[-", "]=", "[="]],
  \ 'on_cmd': ['SignatureToggleSigns', 'SignatureRefresh',
  \            'SignatureListMarks', 'SignatureListMarkers'],
  \ 'hook_post_source': 'sil! exe "doautocmd sig_autocmds BufEnter"',
  \ 'hook_source': "
\\n   let g:SignatureIncludeMarkers = '!@#$%^&*()'
\\n   let g:SignaturePurgeConfirmation = 1
\\n   let g:SignaturePrioritizeMarks = 0
\\n   let g:SignatureMap = {'PurgeMarks': 'm<Del>'}
\"})



"" Highlight motion, lock current color<->regex {{{1
" USE:(directly) nmap <unique> <F1>h     :QuickhlManualList<CR>
" ATTENTION: tag-toggle is unusable on big tag base (like kernels)
" CHG: [[n, qh, qH, <Leader>?h]]
" let g:quickhl_manual_colors = [ "ctermbg=..", ... ]
call dein#add('t9md/vim-quickhl', {
  \ 'on_map': [['n', '<Plug>(operator-quickhl-', '<Plug>(quickhl-']],
  \ 'on_cmd': ['QuickhlManualList', 'QuickhlCwordToggle', 'QuickhlTagToggle',
  \            'QuickhlManualLockToggle', 'QuickhlManualLockWindowToggle'],
  \ 'depends': 'vim-operator-user',
  \ 'hook_add': "
\\n    map <unique> [Quote]h    <Plug>(operator-quickhl-manual-this-motion)
\\n   nmap <unique> [Quote]H    <Plug>(quickhl-manual-reset)
\\n   nmap <unique> [Toggle]h   <Plug>(quickhl-cword-toggle)
\\n   nmap <unique> <Leader>Th  <Plug>(quickhl-manual-toggle)
\\n   nmap <unique> <Leader>TH  <Plug>(quickhl-tag-toggle)
\"})



"" Highlights first space of tab columns {{{1
" EXPL: not in 'hook_source' because plugin isn't lazy
" SEE:(iav_term) RangerChooser
call dein#add('nathanaelkane/vim-indent-guides', {
  \ 'hook_add': _hcat('indent-guides.src') . "\n"
  \." nnoremap <unique> [Toggle]I :IndentGuidesToggle<CR>"})



"" Correlate brackets/tags color with their nesting depth {{{1
" BUG: breaks syntax colors in too many formats (zsh, cmake, etc...)
"  -- Also is culprit for memory/autocmd leaks
" BETTER: lisp, vim --> Activates only specified languages
"   'sh': { 'parentheses': ['start=/(/ end=/)/', 'start=/{/ end=/}/'] }
"   'zsh': { 'parentheses': ['start=/(/ end=/)/', 'start=/{/ end=/}/'] }
call dein#add('luochen1990/rainbow', {
  \ 'on_ft': ['lisp', 'vim', 'tex', 'xml', 'html', 'xhtml', 'php', 'css'],
  \ 'on_cmd': 'RainbowToggle*',
  \ 'hook_add': "noremap <unique> [Toggle]r :<C-u>RainbowToggle<CR>",
  \ 'hook_source': "
\\n   let g:rainbow_active = 1
\\n   let g:rainbow_conf = {'separately': { '*': {}, 'lisp': {}, 'vim': {} }}
\\n   let g:rainbow_conf.ctermfgs = [160, 202, 178, 34, 33, 129]
\\n   let g:rainbow_conf.separately.c = {'ctermfgs': [7, 7] + g:rainbow_conf.ctermfgs}
\"})
