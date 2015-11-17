" ======================================
" FUTURE:
"" Haskell
"NeoBundle 'lukerandall/haskellmode-vim' { 'autoload' : { 'filetypes' : ['haskell', 'hs'] }  }
" eagletmt/ghcmod-vim
" eagletmt/neco-ghc
" dag/vim2hs
" Twinside/vim-haskellConceal
" repository = 'itchyny/vim-haskell-indent'

" Php
" repository = 'shawncplus/phpcomplete.vim'

"" Java
" repository = 'artur-shaik/vim-javacomplete2'

"" Javascript
" repository = 'mxw/vim-jsx'
" repository = 'marijnh/tern_for_vim', build = 'npm install'
" repository = 'jiangmiao/simple-javascript-indenter'
" repository = 'jelera/vim-javascript-syntax'

"" Scala
" derekwyatt/vim-scala

"" Ruby
" NeoBundle 'depuracao/vim-rdoc'

"" Rust
" repository = 'rust-lang/rust.vim'
" repository = 'rhysd/rust-doc.vim'
" repository = 'phildawes/racer'


" Colorize html-codes
" NeoBundleLazy 'lilydjwg/colorizer'
" https://github.com/ap/vim-css-color


"NeoBundle 'MPogoda/octave.vim--'

" Has syntastic integration, allow building CMake from vim.
" TODO: temporarily disabled as I can't understand how to integrate with syntastic
" NeoBundle 'jalcine/cmake.vim'


" The best testing framework for Vim script'
"NeoBundle 'Shougo/vesting'

"NeoBundle 'scrooloose/nerdtree, { 'augroup' : 'NERDTreeHijackNetrw'}'

" ======================================

" Move text (line or vselect) in more friendly way, then :m[ove]
NeoBundleLazy 'matze/vim-move', { 'gui' : 1 }

NeoBundleLazy 'neilagabriel/vim-geeknote', { 'vim_version': '7.4.364',
    \ 'autoload': { 'commands' : ['Geeknote'], }}

" Fast table creation and modification
NeoBundleLazy 'dhruvasagar/vim-table-mode', {
    \ 'autoload': { 'commands' : ['TableModeEnable'], }}

"OFF: NeoBundle 'terryma/vim-smooth-scroll'

" ======================================
" DEPRECATED: use vim-sneak
" NeoBundle 'Lokaltog/vim-easymotion'
" DEPRECATED: use Unite MRU
" NeoBundle 'mhinz/vim-startify'
" DEPRECATED: use 'kana/vim-altr'
" NeoBundle 'vim-scripts/a.vim'
" DEPRECATED: use 'coderifous/textobj-word-column.vim'
" Add new virtual cursor for next occurance of word under cursor
" Or add them for each line of multiline selection
" Ctrl-n  --> Ctrl-p, Ctrl-x, and <Esc>
" NeoBundle 'kris89/vim-multiple-cursors'
" DEPRECATED: use 'rhysd/vim-operator-surround'
" Manage surrounding ('"<p>...) by replace cs"' or delete ds"
" NeoBundle 'tpope/vim-surround'
" DEPRECATED: use 'stefandtw/quickfix-reflector.vim'
" NeoBundleLazy 'jceb/vim-editqf', { 'autoload' : { 'commands' :
"             \ ['QFEdit', 'QFAddNote', 'QFAddPatternNote'] } }

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
