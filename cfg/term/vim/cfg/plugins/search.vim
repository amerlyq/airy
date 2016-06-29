""" Search/Replace

"" HACK evolved rking/ag.vim {{{1
" NEED:[neobundle] v:version >= 7.4.414, REQ: fix List support
" CHECK:DEV: mappings for submode
call dein#add('amerlyq/agn.vim', {'lazy': 0,
  \ 'if': 'executable("ag")',
  \ 'on_map': '<Plug>(ag-',
  \ 'depends': 'vim-operator-user'})

if dein#tap('agn.vim')
  " CHG: all real mappings included into 'after/ftplugin/qf.vim'
  let g:ag = {}
  let g:ag.toggle = {'highlight': 0, 'mapping_message': 0}
  let g:ag.use_default = {'qmappings': 0, 'lmappings': 0}
  " let g:ag.qhandler="botleft lopen 7"  "OR: copen 20"
endif



"" Focus on matching lines, errors, etc by folding away other lines {{{1
call dein#add('embear/vim-foldsearch', {
  \ 'on_cmd': ['Fw', 'Fs', 'Fp', 'Fl', 'FS', 'Fc', 'Fi', 'Fd', 'Fe'],
  \ 'hook_source': "
\\n   \" let g:foldsearch_highlight = 1
\\n   let g:foldsearch_disable_mappings = 1
\"})



"" Delete needless entries from qf/loc wdws and save to correct jumps {{{1
" Change found text directly inside qf/loc and do replace on save
" NOTE: useful for interactive replacing in many files found by :Ag
" DEV: for more precise triggering -- catch au-TextChanged
" ALT: 'thinca/vim-qfreplace', on_ft = ['unite', 'quickfix']
" autocmd MyAutoCmd FileType qf nnoremap <buffer> r :<C-u>Qfreplace<CR>
call dein#add('stefandtw/quickfix-reflector.vim', {
  \ 'on_ft': 'qf'})



""" Substitute/Highlight

"" CHECK: Extension for -incsearch.vim- to provide fuzzy {{{1
" USE: [z/, z?, zg/],
call dein#add('haya14busa/incsearch-fuzzy.vim', {
  \ 'on_source': 'incsearch.vim',
  \ 'on_map': '<Plug>',
  \ 'depends': 'incsearch.vim'})



"" Smart word bounds on '*', and hl w/o jumping by 'z' {{{1
" USE: [*, #, g*, g#, z*, z#, gz*, gz#]
call dein#add('haya14busa/vim-asterisk', {
  \ 'on_source': 'incsearch.vim',
  \ 'on_map': '<Plug>'})



"" Index status/preview for search results (+airline) {{{1
" USE:ALSO [n, N]
call dein#add('osyo-manga/vim-anzu', {
  \ 'on_source': 'incsearch.vim',
  \ 'on_func': 'anzu#',
  \ 'on_map': ['<Plug>', ['n', '<Leader>#', '<Leader>*']],
  \ 'on_cmd': ['AnzuUpdateSearchStatus', 'AnzuSignMatchLine']})



"" CHECK: Multiple realtime hl for searching {{{1
" ATTENTION: place strictly after [incsearch-fuzzy.vim, vim-anzu, vim-asterisk]
"   DEV:ALT: split in individual and #tap for 'incsearch' in each one
" NOTE: vim_version: '7.3'
" USE: [/, ?, g/]
call dein#add('haya14busa/incsearch.vim', {
  \ 'on_map': '<Plug>',
  \ 'depends': 'vim-repeat',
  \ 'hook_add': 'source $DEINHOOKS/incsearch.vim'})



"" Preview replace %s/../../ and %g/../ or search / {{{1
" vim_version: '7.3'
call dein#add('osyo-manga/vim-over', {
  \ 'on_cmd': 'OverCommandLine',
  \ 'hook_add': 'source $DEINHOOKS/over.vim'})
