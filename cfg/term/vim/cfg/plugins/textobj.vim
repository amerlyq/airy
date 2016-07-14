""" Textobj

"" Dependency of 'vim-textobj-*' {{{1
" EXPL: autoload-only -- no sense in being lazy
call dein#add('kana/vim-textobj-user', {'lazy': 0,
  \ 'on_func': 'textobj#user#'})



"" Use only part of any [ai].. textobj {{{1
call dein#add('tommcdo/vim-ninja-feet', {
  \ 'on_map': '<Plug>(ninja',
  \ 'hook_source': 'let g:ninja_feet_no_mappings = 1',
  \ 'hook_add': "
\\n   omap <silent><unique>  <i  <Plug>(ninja-left-foot-inner)
\\n   omap <silent><unique>  <a  <Plug>(ninja-left-foot-a)
\\n   omap <silent><unique>  >i  <Plug>(ninja-right-foot-inner)
\\n   omap <silent><unique>  >a  <Plug>(ninja-right-foot-a)
\\n
\\n   nmap <silent><unique>  z<  <Plug>(ninja-insert)
\\n   nmap <silent><unique>  z>  <Plug>(ninja-append)
\"})



"" Content of closest block pair -- by priority ({[&quot'<`) {{{1
" DEPRECATED: - (old, in jap) osyo-manga/vim-textobj-multiblock
"  - (ALT:TODO: compare) https://github.com/Vesion/vim-textobj-surrounding
"  - (AUGMENT? see gif) https://github.com/gcmt/wildfire.vim
" CHECK: let b:textobj_anyblock_buffer_local_blocks = [ ':', '*' ]
" ALSO: Current enclosing block of ({["'<`
" TODO:THINK:RFC: use getchar() instead of direct mappings?
"   DEV: = Redirect if no such mappings exists (see inside op-surr src)
call dein#add('rhysd/vim-textobj-anyblock', {
  \ 'on_source': 'vim-operator-surround',
  \ 'on_map': [['ox', 'ab', 'ib']],
  \ 'depends': 'vim-textobj-user',
  \ 'hook_add': "
\\n   nmap <silent><unique> [Quote]b <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)
\\n   nmap <silent><unique> [Quote]B <Plug>(operator-surround-delete)<Plug>(textobj-anyblock-a)
\\n   let s:op = '<Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)'
\\n   call Map_blocks('[Quote]', s:op, 'n', 'map')
\"})



"" Between identical found symbols in both directions {{{1
" ALSO: Surrounding symbols for current cursor position (like 'f`')
call dein#add('thinca/vim-textobj-between', {
  \ 'on_source': 'vim-operator-surround',
  \ 'on_map': [['ox', 'af', 'if']],
  \ 'depends': 'vim-textobj-user',
  \ 'hook_add': "
\\n   nmap <silent><unique> [Quote]f <Plug>(operator-surround-replace)<Plug>(textobj-between-a)
\\n   nmap <silent><unique> [Quote]F <Plug>(operator-surround-delete)<Plug>(textobj-between-a)
\"})



"" Use textobj of words column w/o V-BLOCK selection {{{1
" EXPL: too much to wrap for lazy:  (o:IA|x_b:ia)[wWspbBt<>[](){}'"`]
call dein#add('osyo-manga/vim-textobj-blockwise', {'lazy': 0,
  \ 'on_map': {'ox': '<Plug>'},
  \ 'depends': 'vim-textobj-user'})



"" Jump/select git merge conflicts ['<<<' .A. '===' .B. '>>>'] {{{1
call dein#add('rhysd/vim-textobj-conflict', {
  \ 'on_map': [['ox', 'a=', 'i=']],
  \ 'depends': 'vim-textobj-user'})



"" CHECK Direct textobj for N-th '_' partition (SEE name_of_some_func) {{{1
" EXPL: Faster then CamelCaseMotion:  2,wdi,e  -->  d3i_
" CHG 'on_map': [[ox, [ai]{N}(_|<Leader>_)]]
call dein#add('machakann/vim-textobj-delimited', {
  \ 'on_map': {'ox': '<Plug>'},
  \ 'depends': 'vim-textobj-user',
  \ 'hook_source': 'let g:textobj_delimited_no_default_key_mappings = 1',
  \ 'hook_add': "
\\n   call Map_textobj('_', 'delimited-forward')
\\n   call Map_textobj('<Leader>_', 'delimited-backward')
\"})



"" Whole buffer w/[o] empty lines (instead ggVG) {{{1
" CHG 'on_map': [['ox', 'aG', 'iG']]
call dein#add('kana/vim-textobj-entire', {
  \ 'on_map': {'ox': '<Plug>'},
  \ 'depends': 'vim-textobj-user',
  \ 'hook_source': 'let g:textobj_entire_no_default_key_mappings = 1',
  \ 'hook_add': "call Map_textobj('G', 'entire')"})



"" Fold-marked regions {{{1
call dein#add('kana/vim-textobj-fold', {
  \ 'on_map': [['ox', 'az', 'iz']],
  \ 'depends': 'vim-textobj-user'})



"" Function definition+body (C/Java/Vimscript) {{{1
" CHG 'on_map': [[ox, agF, igF, agf, igf]]
call dein#add('kana/vim-textobj-function', {
  \ 'on_map': {'ox': '<Plug>'},
  \ 'depends': 'vim-textobj-user',
  \ 'hook_source': 'let g:textobj_function_no_default_key_mappings = 1',
  \ 'hook_add': "
\\n   call Map_textobj('gf', 'function')
\\n   call Map_textobj('gF', 'function', 'toupper')
\"})



"" Equally indented blocks (Python-like) {{{1
"   [ai] - include empty lines '^$' or stop at them
"   [Ii] - only same indent or also all nested deeper
call dein#add('kana/vim-textobj-indent', {
  \ 'on_map': [['ox', 'ai', 'ii', 'aI', 'iI']],
  \ 'depends': 'vim-textobj-user'})



"" HACK Key/value with/beside quotes and space {{{1
" <Plug>(textobj-[key,value]-*
call dein#add('amerlyq/vim-textobj-keyvalue', {
  \ 'on_map': [['ox', 'ak', 'ik', 'av', 'iv']],
  \ 'depends': 'vim-textobj-user'})



"" Last inserted text {{{1
call dein#add('rhysd/vim-textobj-lastinserted', {
  \ 'on_map': [['ox', 'au', 'iu']],
  \ 'depends': 'vim-textobj-user'})



"" Last pasted text (my gv == vgb) {{{1
call dein#add('saaguero/vim-textobj-pastedtext', {
  \ 'on_map': [['ox', 'gb']],
  \ 'depends': 'vim-textobj-user'})



"" Last searched pattern {{{1
" STD '..[ai]g[nN]'
call dein#add('kana/vim-textobj-lastpat', {
  \ 'on_map': [['ox', 'a/', 'i/']],
  \ 'depends': 'vim-textobj-user'})



"" Line content only (without \n) {{{1
call dein#add('kana/vim-textobj-line', {
  \ 'on_map': [['ox', 'al', 'il']],
  \ 'depends': 'vim-textobj-user'})



"" Any nearest quotes of #'"` {{{1
" Quoted (outer) expr is the most useful:
call dein#add('beloglazov/vim-textobj-quotes', {
  \ 'on_map': [['ox', 'aq', 'iq']],
  \ 'depends': 'vim-textobj-user',
  \ 'hook_add': "omap <silent><unique> q aq"})



"" Vars for bash/perl (like $name{...} ) {{{1
" TODO: maybe space/sigil change mappings to reverse -- G/Q?
" BAD: useless for sigils in cmake like ${VAR}
" CHG 'on_map': [[ox, ad, id]]
call dein#add('vimtaku/vim-textobj-sigil', {
  \ 'on_map': {'ox': '<Plug>'},
  \ 'depends': 'vim-textobj-user',
  \ 'hook_source': 'let g:textobj_sigil_no_default_key_mappings = 1',
  \ 'hook_add': "call Map_textobj('d', 'sigil')"})



"" Space between words or before indent {{{1
" CHG 'on_map': [[ox, as, is]]
call dein#add('saihoooooooo/vim-textobj-space', {
  \ 'on_map': {'ox': '<Plug>'},
  \ 'depends': 'vim-textobj-user',
  \ 'hook_source': 'let g:textobj_space_no_default_key_mappings = 1',
  \ 'hook_add': "call Map_textobj('s', 'space')"})



"" Highlighted syntax region {{{1
" ATTENTION currently textobj-syntax-a acts the same as textobj-syntax-i
" CHG 'on_map': [[ox, ah, ih]]
call dein#add('kana/vim-textobj-syntax', {
  \ 'on_map': {'ox': '<Plug>'},
  \ 'depends': 'vim-textobj-user',
  \ 'hook_source': 'let g:textobj_syntax_no_default_key_mappings = 1',
  \ 'hook_add': "call Map_textobj('h', 'syntax')"})



"" «Smart» words column {{{1
" DEV:FIX: up/down bounds detection -- more smart
" ALT? (column-mappings) osyo-manga/vim-textobj-blockwise
call dein#add('coderifous/textobj-word-column.vim', {
  \ 'on_map': [['ox', 'ac', 'ic', 'aC', 'iC']],
  \ 'depends': 'vim-textobj-user'})
" Make word-columns more dumb, as they are too much «smart» for me
" let g:textobj_word_column_no_smart_boundary_cols = 1
