""" Formatters

"" Align paragraphs by patt {{{1
" ALT:TODO:TRY: another one: lion, etc
call dein#add('godlygeek/tabular', {
  \ 'on_cmd': ['Tab', 'Tabularize'],
  \ 'hook_add': 'source $DEINHOOKS/tabular.vim'
  \})



"" Automatic not-persistent closing statements {{{1
call dein#add('tpope/vim-endwise', {
  \ 'on_map': [['i', '<CR>', '<C-x><CR>']]})



"" Type-specific folding {{{1
call dein#add('thinca/vim-ft-diff_fold', {'on_ft': 'diff'})
call dein#add('thinca/vim-ft-vim_fold', {'on_ft': 'vim'})
call dein#add('thinca/vim-ft-help_fold', {'on_ft': 'help'})



"" Auto-formatter for c/cpp/obj-c {{{1
call dein#add('rhysd/vim-clang-format', {
  \ 'if': 'executable("clang-format")',
  \ 'on_map': '<Plug>(operator-clang-format)',
  \ 'on_cmd': ['ClangFormat', 'ClangFormatEchoFormattedCode'],
  \ 'on_ft': ['c', 'cpp', 'objc'],
  \ 'depends': 'vim-operator-user',
  \ 'hook_source': 'source $DEINHOOKS/clang-format.vim'})



"" (DISABLED) Autoformatting with one button, can use custom (like clang-styler) {{{1
" ATTENTION: Not operator, but placed near to 'vim-clang-format'
" 'if': 'executable("clang-format")||executable("astyle")||executable("tidy")',
call dein#add('Chiel92/vim-autoformat', {'if': 0,
  \ 'on_cmd': ['Autoformat', 'NextFormatter', 'NextFormatter'],
  \ 'hook_add': 'noremap <unique> <F6> :Autoformat<CR><CR>'})
