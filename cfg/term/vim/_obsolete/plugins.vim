" ======================================
" FUTURE:
"" Haskell
"NeoBundle 'lukerandall/haskellmode-vim' { 'autoload' : { 'filetypes' : ['haskell', 'hs'] }  }
" eagletmt/ghcmod-vim
" eagletmt/neco-ghc
" dag/vim2hs
" Twinside/vim-haskellConceal

"" Scala
" derekwyatt/vim-scala

"" Ruby
" NeoBundle 'depuracao/vim-rdoc'


"NeoBundle 'MPogoda/octave.vim--'

" Has syntastic integration, allow building CMake from vim.
" TODO: temporarily disabled as I can't understand how to integrate with syntastic
" NeoBundle 'jalcine/cmake.vim'


" The best testing framework for Vim script'
"NeoBundle 'Shougo/vesting'

" Always have a nice view for vim split windows
" http://zhaocai.github.io/GoldenView.Vim/
"NeoBundle 'zhaocai/GoldenView.Vim'


" ======================================
" DEPRECATED: use vim-sneak
" NeoBundle 'Lokaltog/vim-easymotion'
" DEPRECATED: use Unite MRU
" NeoBundle 'mhinz/vim-startify'
" DEPRECATED: use 'kana/vim-altr'
" NeoBundle 'vim-scripts/a.vim'

" ======================================
" DISABLED: breaks syntax colors in too many formats (zsh, cmake, etc...)
" Also is culprit for memory/autocmd leaks
" NeoBundle 'luochen1990/rainbow'
" DISABLED: has problems with russian text
" Insert mode auto-completion for quotes, parens, brackets, etc
"NeoBundle 'Raimondi/delimitMate'
" DISABLED: bug with neocomplete -- <BS> don't remove both brackets,
" unnecessary quotes for my workflow, partially superseeded by vim-surround
"NeoBundle 'kana/vim-smartinput'
" DISABLED: completely destroys mouse selection. Has not much usecases.
"NeoBundle 'joonty/vdebug', {
"            \ 'autoload' : { 'filetypes' : [ 'python' ] } }
