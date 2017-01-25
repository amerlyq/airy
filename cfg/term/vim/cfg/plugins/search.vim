""" Search/Replace

"" HACK evolved rking/ag.vim {{{1
" NEED:[neobundle] v:version >= 7.4.414, REQ: fix List support
" CHG: all real mappings included into 'after/ftplugin/qf.vim'
" CHECK:DEV: mappings for submode
" let g:ag.qhandler="botleft lopen 7"  "OR: copen 20"
call dein#add('amerlyq/agn.vim', {'lazy': 0,
  \ 'if': executable('ag'),
  \ 'on_map': '<Plug>(ag-',
  \ 'depends': 'vim-operator-user',
  \ 'hook_source': "
\\n   let g:ag = {}
\\n   let g:ag.toggle = {'highlight': 0, 'mapping_message': 0}
\\n   let g:ag.use_default = {'qmappings': 0, 'lmappings': 0}
\"})


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

"" CHECK: Multiple realtime hl for searching {{{1
" NOTE: vim_version: '7.3'
" FIXED:('if': 0): for 'nvim segfault encode_tv2string()' or ':mess incsearch recursive'
call dein#add('haya14busa/incsearch.vim', {
  \ 'on_source': ['incsearch-fuzzy.vim', 'vim-anzu', 'vim-asterisk'],
  \ 'on_map': '<Plug>',
  \ 'depends': 'vim-repeat',
  \ 'hook_source': _hcat('incsearch.src'),
  \ 'hook_add': "
\\n   map <unique> /  <Plug>(incsearch-forward)
\\n   map <unique> ?  <Plug>(incsearch-backward)
\\n   map <unique> g/ <Plug>(incsearch-stay)
\\n   for c in ['n', 'N']
\\n     call Map_nxo(c, '<Plug>(incsearch-nohl-'.c.')')
\\n   endfor
\"})



"" CHECK: Extension for -incsearch.vim- {{{1
" NOTE: combined fuzzy/fuzzyspell
call dein#add('haya14busa/incsearch-fuzzy.vim', {
  \ 'if': 'dein#tap("incsearch.vim")',
  \ 'on_func': 'incsearch#config#fuzzy',
  \ 'on_map': '<Plug>',
  \ 'depends': 'incsearch.vim',
  \ 'hook_add': "
\\n   fun! s:cfg_fuzzy(...) abort
\\n     return extend(copy({'converters': [
\\n     \   incsearch#config#fuzzy#converter(),
\\n     \   incsearch#config#fuzzyspell#converter()
\\n     \ ]}), get(a:, 1, {}))
\\n   endf
\\n   noremap <silent><unique><expr>  z/  incsearch#go(<SID>cfg_fuzzy())
\\n   noremap <silent><unique><expr>  z?  incsearch#go(<SID>cfg_fuzzy({'command': '?'}))
\\n   noremap <silent><unique><expr>  z;  incsearch#go(<SID>cfg_fuzzy({'is_stay': 1}))
\"})



"" Index status/preview for search results (+airline) {{{1
" NOTE: airline ext is good for terminal vim to not jump cursor in cmdline
" SEE unite-anzu -- {Pattern} in matching lines are output in unite.vim
"   : Unite anzu: {pattern}
" FIXME: <Plug>(anzu-sign-matchline)  " USE:ALSO [n, N]
" EXPL:(w/o <unique>) :: remaps after incsearch
" EXPL:(on_map) inside hook to mitigate issue w/ lazy-load for multiple <Plug>
" EXPL:(depends) fake dependency to force order in 'load_state'
" THINK:MAYBE: combine ',#' view when using 'z*' or '/' instead of sep maps?
call dein#add('osyo-manga/vim-anzu', {
  \ 'if': 'dein#tap("incsearch.vim")',
  \ 'on_source': 'vim-asterisk',
  \ 'on_func': 'anzu#',
  \ 'on_map': ['<Plug>', ['n', '<Leader>#', '<Leader>*']],
  \ 'on_cmd': ['AnzuUpdateSearchStatus', 'AnzuSignMatchLine'],
  \ 'depends': 'incsearch.vim',
  \ 'hook_source': "
\\n nmap <silent><unique>  <Leader>#
\       <Plug>(incsearch-nohl)<Plug>(anzu-jump)<Plug>(anzu-mode)
\\n nmap <silent><unique>  <Leader>*
\       <Plug>(incsearch-nohl)<Plug>(anzu-n)<Plug>(anzu-mode)
\", 'hook_add': "
\\n   nmap  n  <Plug>(incsearch-nohl)<Plug>(anzu-n-with-echo)
\\n   nmap  N  <Plug>(incsearch-nohl)<Plug>(anzu-N-with-echo)
\"})



"" Smart word bounds on '*', and hl w/o jumping by 'z' {{{1
" DISABLED: irritates sometimes, plus has highlighting bugs
"   let g:asterisk#keeppos = 1  " Keep cursor inside match at same position
" EXPL: z-prefixed mappings doesn't move the cursor.
" USE: [*, #, g*, g#, z*, z#, gz*, gz#], z8 -- Easier to press
call dein#add('haya14busa/vim-asterisk', {
  \ 'if': 'dein#tap("incsearch.vim")',
  \ 'on_map': '<Plug>',
  \ 'hook_add': "
\\n   for k in ['*', '#', 'g*', 'g#', 'z*', 'z#', 'gz*', 'gz#']
\\n     exe 'map <unique> '.k.' <Plug>(incsearch-nohl'.(k=~#'z'?'0':'').')'.
\         '<Plug>(asterisk-'.k.')<Plug>(anzu-update-search-status-with-echo)'
\\n   endfor
\\n   exe 'map <unique> z8 <Plug>(incsearch-nohl0)<Plug>(asterisk-z*)'.
\         '<Plug>(anzu-update-search-status-with-echo)'
\"})



"" Preview replace or search {{{1
" LIOR: :OverCommandLine<CR> and in standalone input your expr:
"   %s/../.../g  OR  /...  OR  %g/.../d
" vim_version: '7.3'
" ALT: AndrewRadev/multichange.vim
call dein#add('osyo-manga/vim-over', {
  \ 'on_cmd': 'OverCommandLine',
  \ 'hook_source': _hcat('over.src'),
  \ 'hook_add': "let g:subs_wrap = 'OverCommandLine %s<CR>'"
  \."\n" . _hcat('over.add')})
