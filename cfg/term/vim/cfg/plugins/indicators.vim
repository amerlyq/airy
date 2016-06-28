""" Indicators

"" Signs on changes and textobj on vcs-aware area {{{1
" ALT: airblade/vim-gitgutter: (git only, but much faster file save)
" EXPL: show from the start. Disable individually by ft.
" CHG: <Plug>
call dein#add('mhinz/vim-signify', {'lazy': 0,
  \ 'on_map': [['xo', 'aS', 'iS'], ['n', '[c', ']c']],
  \ 'on_cmd': ['SignifyFold', 'SignifyToggle',
  \            'SignifyToggleHighlight', 'SignifyRefresh']})

" ATTENTION: not in 'hook_source' because plugin isn't lazy
if dein#tap('vim-signify')
  let g:signify_vcs_list = [ 'git', 'hg', 'cvs' ]
  let g:signify_sign_change = '~'
  let g:signify_sign_delete = '-'

  noremap <unique> zS :<C-u>SignifyFold<CR>
  " FIND:THINK: isn't :SignifyRefresh unnecessary?
  noremap <unique> [Toggle]g :<C-u>SignifyToggleHighlight\|SignifyRefresh<CR>
  noremap <unique> [Toggle]G :<C-u>SignifyToggle<CR>
  "" Already mapped -- if busy: automaps <leader>gj and <leader>gk
  nmap <silent><unique> ]c <Plug>(signify-next-hunk)
  nmap <silent><unique> [c <Plug>(signify-prev-hunk)
  " Textobj -- changed areas
  xmap <silent><unique> aS <Plug>(signify-motion-outer-visual)
  omap <silent><unique> aS <Plug>(signify-motion-outer-pending)
  xmap <silent><unique> iS <Plug>(signify-motion-inner-visual)
  omap <silent><unique> iS <Plug>(signify-motion-inner-pending)
endif



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
\\n  let g:SignatureIncludeMarkers = '!@#$%^&*()'
\\n  let g:SignaturePurgeConfirmation = 1
\\n  let g:SignaturePrioritizeMarks = 0
\\n  let g:SignatureMap = {'PurgeMarks': 'm<Del>'}
\"})



"" Highlight motion, lock current color<->regex {{{1
" CHG: [[n, qh, qH, <Leader>?h]]
call dein#add('t9md/vim-quickhl', {
  \ 'on_map': [['n', '<Plug>(operator-quickhl-', '<Plug>(quickhl-']],
  \ 'on_cmd': ['QuickhlManualList', 'QuickhlCwordToggle', 'QuickhlTagToggle',
  \            'QuickhlManualLockToggle', 'QuickhlManualLockWindowToggle'],
  \ 'depends': 'vim-operator-user'})

if dein#tap('vim-quickhl')
   map <unique> [Quote]h    <Plug>(operator-quickhl-manual-this-motion)
  nmap <unique> [Quote]H    <Plug>(quickhl-manual-reset)
  " USE:(directly) nmap <unique> <F1>h     :QuickhlManualList<CR>
  nmap <unique> [Toggle]h   <Plug>(quickhl-cword-toggle)
  nmap <unique> <Leader>Th  <Plug>(quickhl-manual-toggle)
  "" ATTENTION: unusable on big tag base (like kernels)
  nmap <unique> <Leader>TH  <Plug>(quickhl-tag-toggle)
  " let g:quickhl_manual_colors = [ "ctermbg=..", ... ]
endif



"" Highlights first space of tab columns {{{1
" SEE:(iav_term) RangerChooser
" NOTE: Make 1-wide guide, don't works on Hard-Tabs
" NOTE: At the moment Terminal Vim only has basic support.
"     -- So colors won't be autocalculated from your colorscheme.
call dein#add('nathanaelkane/vim-indent-guides')

" ATTENTION: not in 'hook_source' because plugin isn't lazy
if dein#tap('vim-indent-guides')
  nnoremap <unique> [Toggle]I :IndentGuidesToggle<CR>

  let g:indent_guides_enable_on_vim_startup = 1
  let g:indent_guides_exclude_filetypes = ['votl', 'iav_term']

  let g:indent_guides_guide_size = 1
  let g:indent_guides_start_level = 2
  let g:indent_guides_indent_levels = 20
  let g:indent_guides_tab_guides = 0

  let g:indent_guides_auto_colors = 0
  let g:indent_guides_color_change_percent = 10
  let g:indent_guides_default_mapping = 0
endif



"" Correlate brackets/tags color with their nesting depth {{{1
" BUG: breaks syntax colors in too many formats (zsh, cmake, etc...)
"  -- Also is culprit for memory/autocmd leaks
" BETTER: lisp, vim --> Activates only specified languages
"   'sh': { 'parentheses': ['start=/(/ end=/)/', 'start=/{/ end=/}/'] }
"   'zsh': { 'parentheses': ['start=/(/ end=/)/', 'start=/{/ end=/}/'] }
call dein#add('luochen1990/rainbow', {
  \ 'on_ft': ['lisp', 'vim', 'tex', 'xml', 'html', 'xhtml', 'php', 'css'],
  \ 'hook_source': "
\\n  let g:rainbow_active = 1
\\n  let g:rainbow_conf = {'separately': { '*': 0, 'lisp': {}, 'vim': {} }}
\\n  let g:rainbow_conf.ctermfgs = [160, 202, 178, 34, 33, 129]
\\n  let g:rainbow_conf.separately.c = {'ctermfgs': [7, 7] + g:rainbow_conf.ctermfgs}
\"})
