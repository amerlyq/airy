""" Formatters

"" Align paragraphs by patt {{{1
" ALT:TODO:TRY: another one: lion, etc
call dein#add('godlygeek/tabular', {
  \ 'on_cmd': ['Tabi', 'Tabularize'],
  \ 'hook_source': 'source $DEINHOOKS/tabular.src.vim',
  \ 'hook_add': 'source $DEINHOOKS/tabular.add.vim'})



"" Automatic not-persistent closing statements {{{1
" BUG:(intermitten) when editing prev-to-last char, inserting ',' and pressing <CR>
"   -- than last char remains on the same line instead of dropping to next
call dein#add('tpope/vim-endwise', {
  \ 'on_map': [['i', '<CR>', '<C-x><CR>']]})



"" Type-specific folding {{{1
call dein#add('thinca/vim-ft-diff_fold', {'on_ft': 'diff'})
call dein#add('thinca/vim-ft-vim_fold', {'on_ft': 'vim'})
call dein#add('thinca/vim-ft-help_fold', {'on_ft': 'help'})



"" TRY?DEV:USE: great idea and skeleton, but conflicts with my FoldText. SEE help.
" NOTE: not bad idea with single solid horizontal separator instead any text at all.
"       Add this as separate toggle option.
" LucHermitte/VimFold4C:
"   description: Reactive vim fold plugin for C & C++ (and similar languages)
"   \ 'on_ft': [c, cpp]



"" Auto-formatter for c/cpp/obj-c {{{1
call dein#add('rhysd/vim-clang-format', {
  \ 'if': executable('clang-format'),
  \ 'on_map': '<Plug>(operator-clang-format)',
  \ 'on_cmd': ['ClangFormat', 'ClangFormatEchoFormattedCode'],
  \ 'on_ft': ['c', 'cpp', 'objc'],
  \ 'depends': 'vim-operator-user',
  \ 'hook_source': 'source $DEINHOOKS/clang-format.src.vim'})



"" (DISABLED) Autoformatting with one button, can use custom (like clang-styler) {{{1
" ATTENTION: Not operator, but placed near to 'vim-clang-format'
" 'if': executable("clang-format")||executable("astyle")||executable("tidy"),
call dein#add('Chiel92/vim-autoformat', {'if': 0,
  \ 'on_cmd': ['Autoformat', 'NextFormatter', 'NextFormatter'],
  \ 'hook_add': 'noremap <unique> <F6> :Autoformat<CR><CR>'})
