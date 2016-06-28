
"" Auto-formatter for c/cpp/obj-c {{{1
call dein#add('rhysd/vim-clang-format', {
  \ 'if': 'executable("clang-format")',
  \ 'on_map': '<Plug>(operator-clang-format)',
  \ 'on_cmd': ['ClangFormat', 'ClangFormatEchoFormattedCode'],
  \ 'on_ft': ['c', 'cpp', 'objc'],
  \ 'depends': ['vim-operator-user', 'vimproc.vim'],
  \ 'hook_source': 'source $DEINHOOKS/clang-format.vim'})


"" (DISABLED) Autoformatting with one button, can use custom (like clang-styler) {{{1
" ATTENTION: Not operator, but placed near to 'vim-clang-format'
" 'if': 'executable("clang-format")||executable("astyle")||executable("tidy")',
call dein#add('Chiel92/vim-autoformat', {'if': 0,
  \ 'on_cmd': ['Autoformat', 'NextFormatter', 'NextFormatter'],
  \ 'hook_add': 'noremap <unique> <F6> :Autoformat<CR><CR>'})


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
  \ 'hook_source': 'source $DEINHOOKS/cscope.vim',
  \ 'hook_post_source': 'CCTree'})
