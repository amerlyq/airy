""" Source-code analysis

"" Display static callgraphs by reading a cscope database {{{1
" Works for C programs. SEE https://sites.google.com/site/vimcctree/
" TRY:SEE: depends: hari-rangarajan/ccglue  (SEE building, configuring to interact)
" NOT:EXPL: must be loaded only on-demand by commands!
"   - filetypes: [c, cpp]
"   - mappings: [[n, <LocalLeader>f, <LocalLeader>r]]
" EXPL:(hook_add) Launch with default DB
" EXPL:(hook_post_source) Load DB by using lazy mappings
call dein#add('hari-rangarajan/CCTree', {
  \ 'on_cmd': 'CCTreeLoadDB',
  \ 'hook_add': 'com! -bar CCTree'.
  \   ' if !filereadable("cscope.out")| CCgen |en| CCTreeLoadDB cscope.out',
  \ 'hook_source': _hcat('cscope.src'),
  \ 'hook_post_source': 'CCTree'})



"" CHECK GNU GLOBAL 6.0 is a source code tagging system {{{1
" SEE https://www.gnu.org/software/global/
call dein#add('hewes/unite-gtags', {
  \ 'if': executable('global'),
  \ 'on_source': 'unite.vim'})



" Alt: bb:abudden/taghighlight "(small and fast) from bitbucket {{{1
" NOTE: easytags can make CursorMove very slow
"   https://github.com/xolox/vim-easytags/issues/68#issuecomment-28480981
"NeoBundle xolox/vim-easytags, { \ 'depends': xolox/vim-misc }
