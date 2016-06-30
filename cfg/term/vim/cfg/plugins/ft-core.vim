""" Cpp {{{1

" ALT: vim-jp/cpp-vim
call dein#add('octol/vim-cpp-enhanced-highlight', {
  \ 'on_ft': ['c', 'h', 'hpp', 'cpp']})


"" GNU Assembler
call dein#add('Shirk/vim-gas')



" SEE:
" vim-scripts/DoxygenToolkit.vim:
" beyondmarc/opengl.vim: {}



""" Python {{{1

call dein#add('hynek/vim-python-pep8-indent', {
  \ 'on_ft': 'python'})



" BUG: update error
" on_cmd: Pyimport
call dein#add('davidhalter/jedi-vim', {
  \ 'on_ft': 'python',
  \ 'hook_source': 'source $DEINHOOKS/jedi-vim.src.vim'})



" mappings: [ [[, ]], [M, ]M, [ai]C, [ai]M ]
call dein#add('klen/python-mode', {
  \ 'rev': 'develop',
  \ 'on_ft': 'python'})



" USAGE: ..[ai][fc]  {[]}p[fc] -- next/prev func/class
" https://github.com/bps/vim-textobj-python



""" Haskell {{{1

call dein#add('lukerandall/haskellmode-vim', {
  \ 'on_ft': 'haskell',
  \ 'hook_source': "let g:haddock_browser = 'r.b'"})



" ALT repo = 'kana/vim-filetype-haskell'
" ALT repo = 'itchyny/vim-haskell-indent'
" on_ft = 'haskell'



" Integration with syntastic
call dein#add('eagletmt/ghcmod-vim', {
  \ 'if': executable('ghc-mod'),
  \ 'on_ft': 'haskell'})



""" Java {{{1

" albfan/vim-jide
" https://github.com/JalaiAmitahl/maven-compiler.vim
" albfan/JavaDecompiler.vim

" hsanson/vim-android: {}



""" Others {{{1

call dein#add('vim-perl/vim-perl', {
  \ 'on_ft': 'perl'})



" mappings: [C-xC-o, [[, ]], ([, ((, )), F5, F7]
call dein#add('LaTeX-Box-Team/LaTeX-Box', {
  \ 'if': executable('latexmk'),
  \ 'on_ft': ['tex', 'bib', 'latex'],
  \ 'hook_source': 'source $DEINHOOKS/latex-box.src.vim'})



"" Testing framework for vimscript
" ALT: 'thinca/vim-themis'
call dein#add('albfan/vader.vim', {
  \ 'on_ft': 'vader'})
