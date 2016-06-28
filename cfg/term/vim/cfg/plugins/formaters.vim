
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
