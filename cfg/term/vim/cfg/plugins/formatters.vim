""" Formatters

"" Align paragraphs by patt {{{1
" ALT:TODO:TRY: another one: lion, etc
call dein#add('godlygeek/tabular', {
  \ 'on_cmd': ['Tabi', 'Tabularize'],
  \ 'hook_source': _hcat('tabular.src'),
  \ 'hook_add': _hcat('tabular.add')})



"" HACK: lyrics multicolumn /multiverse editor to show in ncmpcpp
call dein#add('amerlyq/lyrics-ed.vim', {
  \ 'on_func': 'lyrics#',
  \ 'on_cmd': ['LyricsLoad', 'Lyrics*']})



"" Automatic not-persistent closing statements {{{1
call dein#add('tpope/vim-endwise', {'on_i': 1})



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
" 'hook_add': "map gQ  <Plug>(operator-clang-format)",
call dein#add('rhysd/vim-clang-format', {
  \ 'if': executable('clang-format'),
  \ 'on_map': [['nx', '<Plug>(operator-clang-format)']],
  \ 'on_cmd': ['ClangFormat', 'ClangFormatEchoFormattedCode'],
  \ 'on_ft': ['c', 'cpp', 'objc'],
  \ 'depends': 'vim-operator-user',
  \ 'hook_source': _hcat('clang-format.src')})



"" Autoformatting with one button, can use custom (like clang-styler) {{{1
" ATTENTION: Not operator, but placed near to 'vim-clang-format'
" 'if': executable("clang-format")||executable("astyle")||executable("tidy"),
call dein#add('Chiel92/vim-autoformat', {
  \ 'on_cmd': ['Autoformat', 'NextFormatter', 'NextFormatter'],
  \ 'hook_add': 'noremap <unique> <F6> :Autoformat<CR><CR>'})
