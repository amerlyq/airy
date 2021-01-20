""" Cpp {{{1

" ALT: vim-jp/cpp-vim
call dein#add('octol/vim-cpp-enhanced-highlight', {
  \ 'on_ft': ['c', 'h', 'hpp', 'cpp']})


"" GNU Assembler
call dein#add('Shirk/vim-gas')


call dein#add('ollykel/v-vim')


" SEE:
" vim-scripts/DoxygenToolkit.vim:
" beyondmarc/opengl.vim: {}



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


" USAGE: sbcl --load /etc/default/quicklisp --load ~/.cache/vim/dein/repos/github.com/l04m33/vlime/lisp/start-vlime.lisp
call dein#add('l04m33/vlime', {
  \ 'if': 0,
  \ 'rtp': 'vim/',
  \ 'on_ft': 'lisp',
  \ 'hook_source': "
\\n   let g:vlime_force_default_keys = 1
\\n   let g:vlime_compiler_policy = {'DEBUG': 3}
\"})


" REF: https://kovisoft.bitbucket.io/tutorial.html
call dein#add('kovisoft/slimv', {
  \ 'rtp': 'vim/',
  \ 'on_ft': 'lisp',
  \ 'hook_source': "
\\n let g:slimv_swank_cmd = \"!ros -e '(ql:quickload :swank) (swank:create-server)' wait &\"
\\n let g:slimv_lisp = 'ros run'
\\n let g:slimv_impl = 'sbcl'
\"})


" mappings: [C-xC-o, [[, ]], ([, ((, )), F5, F7]
call dein#add('LaTeX-Box-Team/LaTeX-Box', {
  \ 'if': executable('latexmk'),
  \ 'on_ft': ['tex', 'bib', 'latex'],
  \ 'hook_source': _hcat('latex-box.src')})



"" Testing framework for vimscript
" ALT: 'thinca/vim-themis'
" NEW? https://github.com/hupfdule/vader.vim/commit/d0432d92289eb5ffb7b34dd11e541d30fb2618da
call dein#add('junegunn/vader.vim', {
  \ 'on_ft': 'vader'})
