""" Source-code analysis

"" Display static callgraphs by reading a cscope database {{{1
" Works for C programs. SEE https://sites.google.com/site/vimcctree/
" TRY:SEE: depends: hari-rangarajan/ccglue  (SEE building, configuring to interact)
" NOT:EXPL: must be loaded only on-demand by commands!
"   - filetypes: [c, cpp]
"   - mappings: [[n, <LocalLeader>f, <LocalLeader>r]]
" EXPL:(hook_add) Launch with default DB
" EXPL:(hook_post_source) Load DB by using lazy mappings
" BAD: too slow startup (>10m) on large db >100Mb
" ALT:BET?(faster?) spacemacs + cscope
"   https://sourceforge.net/projects/kscope/
"   OLD https://sourceforge.net/projects/cbrowser/
" USAGE: $ cscope -bcqR && ctags -R && ccglue -I
"  => :CCTreeLoadXRefDB ccglue.out
call dein#add('hari-rangarajan/CCTree', {
  \ 'on_cmd': ['CCTreeLoadDB', 'CCTreeLoadXRefDBFromDisk'],
  \ 'hook_add': 'com! -bar CCTree'.
  \   ' if !filereadable("cscope.out")| CCgen |en| CCTreeLoadDB cscope.out',
  \ 'hook_source': _hcat('cscope.src'),
  \ 'hook_post_source': 'CCTree'})



"" CHECK GNU GLOBAL 6.0 is a source code tagging system {{{1
" SEE https://www.gnu.org/software/global/
"   + http://stackoverflow.com/questions/28475573/can-gtags-navigate-back
"   ~ http://vi.stackexchange.com/questions/4991/using-gnu-global-and-gtags-cscope-in-vim
" NOTE: bundled in >v6.3.2 https://github.com/yoshizow/global-pygments-plugin
" ALSO:
"   https://github.com/qianjigui/gtags.vim
"   https://github.com/bbchung/gtags.vim
"   http://stackoverflow.com/questions/28475573/can-gtags-navigate-back
call dein#add('hewes/unite-gtags', {
  \ 'if': executable('global'),
  \ 'lazy': 0})
  " \ 'on_source': 'unite.vim'})



" Alt: bb:abudden/taghighlight "(small and fast) from bitbucket {{{1
" NOTE: easytags can make CursorMove very slow
"   https://github.com/xolox/vim-easytags/issues/68#issuecomment-28480981
"NeoBundle xolox/vim-easytags, { \ 'depends': xolox/vim-misc }
