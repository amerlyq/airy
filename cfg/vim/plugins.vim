" vim: foldmethod=marker
" :NeoBundleClearCache if change .vimrc

let mapleader="\\"


NeoBundle 'Valloric/ListToggle'
" Ascii graph drawing in vim
NeoBundleLazy 'vim-scripts/DrawIt'

"==========================================
" All commands below will use this leader, commands above -- will use '\'
"==========================================

let mapleader=","
"noremap \ ,


" Let NeoBundle manage NeoBundle
NeoBundleFetch 'Shougo/neobundle.vim'
" git clone --depth 1 https://github.com/Shougo/neobundle.vim ~/.vim/bundle/neobundle.vim
" vim +NeoBundleInstall +qall

"NeoBundle 'user/repo', {
"\ 'lazy' : 1,
"\ 'autoload' : {
"\ 'filetypes' : ['vim', 'elisp']
"\ 'commands' : ['Command']
"\ 'mappings' : ['<Plug>(pluign_mapping)']
"\ }
"\}
" MSG: build : { 'windows' : 'echo "Sorry, cannot update vimproc binary file in Windows."' }


" Asynchronous execution plugin for Vim
"   let vimproc_updcmd = has('win64') ?
"     \ 'tools\\update-dll-mingw 64' : 'tools\\update-dll-mingw 32'
" 'windows' : vimproc_updcmd,
NeoBundle 'Shougo/vimproc',{
    \ 'external_commands' : 'make',
    \ 'build' : {
    \   'windows' : 'make -f make_mingw32.mak',
    \   'cygwin' : 'make -f make_cygwin.mak',
    \   'mac' : 'make -f make_mac.mak',
    \   'unix' : 'make -f make_unix.mak',
    \ }}

"" Commented out section
    " \ 'build' : {
    " \   'windows' : 'make -f make_mingw32.mak',
    " \   'cygwin' : 'make -f make_cygwin.mak',
    " \   'mac' : 'make -f make_mac.mak',
    " \   'unix' : 'make -f make_unix.mak',
    " \   },
" Powerful shell implemented by Vim script
NeoBundleLazy 'Shougo/vimshell.vim', {
    \ 'depends' : 'Shougo/vimproc.vim',
    \ 'external_commands' : 'make',
    \ 'autoload' : {
    \   'commands' : [{ 'name' : 'VimShell',
    \                   'complete' : 'customlist,vimshell#complete'},
    \                 'VimShellExecute', 'VimShellInteractive',
    \                 'VimShellTerminal', 'VimShellPop',
    \              ],
    \   'mappings' : ['<Plug>(vimshell_'],
    \ }}

" DEPRECATED: use snip-ranger-filechooser.vim
" NeoBundleLazy 'Shougo/vimfiler', {
"     \ 'depends' : 'Shougo/unite.vim',
"     \ 'autoload' : {
"     \    'commands' : [{ 'name' : 'VimFiler',
"     \                    'complete' : 'customlist,vimfiler#complete' },
"     \                  'VimFilerExplorer',
"     \                  'Edit', 'Read', 'Source', 'Write'],
"     \    'mappings' : ['<Plug>(vimfiler_'],
"     \    'explorer' : 1,
"     \ }}

" Ultimate hex-editing system,  depends on hexript for some optional scripts
NeoBundle 'Shougo/vinarise.vim', {
    \ 'depends' : 'rbtnn/hexript.vim',
    \ 'autoload' : {
    \    'commands' : ['Vinarise', 'VinariseDump'],
    \    'explorer' : 1,
    \ }}

" The best testing framework for Vim script'
"NeoBundle 'Shougo/vesting'


" Always have a nice view for vim split windows
" http://zhaocai.github.io/GoldenView.Vim/
"NeoBundle 'zhaocai/GoldenView.Vim'

" Super-mega-replace for bunch of plugins
" See: http://bling.github.io/blog/2013/06/02/unite-dot-vim-the-plugin-you-didnt-know-you-need/
NeoBundle 'Shougo/unite.vim', { 'name' : 'unite.vim'
                            \ , 'depends' : 'Shougo/vimproc'
                            \ }
NeoBundleLazy 'Shougo/unite-outline', {
    \ 'depends' : 'unite.vim'
    \ , 'autoload' : { 'unite_sources' : 'outline' }
    \ }
NeoBundle 'Shougo/neomru.vim', { 'depends' : 'unite.vim' }

" NeoBundleLazy 'thinca/vim-unite-history', { 'depends' : 'unite.vim'
"                                         \ , 'autoload' : { 'unite_sources' : 'history/command' }
"                                         \ }

" ======================================

" Integration with neocomplete: for stdlib++, boost, etc (works on Windows)
" http://www.reddit.com/r/vim/comments/1x4mvg/vimmarching_with_neocomplete_doesnt_complete_c/
NeoBundle 'osyo-manga/vim-marching', {
    \ 'depends' : 'Shougo/vimproc'
    \ }

NeoBundleLazy 'Shougo/neocomplete', {
    \ 'vim_version' : '7.3.885',
    \ 'depends' : 'Shougo/context_filetype.vim',
    \ 'disabled' : !has('lua'),
    \ 'autoload': {
    \   'insert': 1,
    \ }}
" SirVer/ultisnips
NeoBundle 'Shougo/neosnippet.vim', {
    \ 'vim_version': '7.3.885',
    \ 'depends' :
    \   [ 'Shougo/neocomplete.vim'
    \   , 'Shougo/neosnippet-snippets'
    \   , 'honza/vim-snippets'
    \   ],
    \ }

if has('unix')

    " W3m from vim
    "NeoBundle 'yuratomo/w3m.vim'

    "Lazy loading like this
    "NeoBundleLazy 'Rip-Rip/clang_complete'
    "autocmd FileType c,cpp NeoBundleSource clang_complete

    "" Autocompletion for Python and C-like languages
    " NeoBundle 'Valloric/YouCompleteMe', {
    "         \ 'lazy': 1,
    "         \ 'augroup': 'youcompletemeStart',
    "         \ 'autoload': {
    "         \   'insert': 1,
    "         \   'commands' : ['Ycm'],
    "         \ },
    "         \ 'build': {
    "         \   'unix': './install.sh --clang-completer --system-libclang',
    "         \ },
    "         \ 'disabled': !has('python'),
    "         \ 'vim_version': '7.3.584',
    "         \}

    " [ ! -e './third_party/ycmd/ycm_core.so' ]
    " It could be necessary to exac inside of bundle/YouCompleteMe
    " git submodule update --init --recursive
" {{{Build instruction for YCM
"   1. git submodule update --init --recursive
"   2. cd third_party/ycmd
"   3. mkdir -p build
"   4. cd build
"   5. cmake .. ../cpp
"   5a. (optional) ccmake . # configure
"   6. make
" }}}
    " For win: https://github.com/Valloric/YouCompleteMe/wiki/Windows-Installation-Guide

endif
" ======================================
" Readline style insertion
" http://www.vim.org/scripts/script.php?script_id=4359
NeoBundle 'tpope/vim-rsi'
NeoBundle 'tpope/vim-endwise'
NeoBundle 'tpope/vim-repeat'
" Manage surrounding ('"<p>...) by replace cs"' or delete ds"
NeoBundle 'tpope/vim-surround'
" Manage function arguments with textobj 'a,' 'i,', shifting with '<,' '>,'
NeoBundle 'PeterRincker/vim-argumentative'

" DISABLED: has problems with russian text
" Insert mode auto-completion for quotes, parens, brackets, etc
"NeoBundle 'Raimondi/delimitMate'
" DISABLED: bug with neocomplete -- <BS> don't remove both brackets,
" unnecessary quotes for my workflow, partially superseeded by vim-surround
"NeoBundle 'kana/vim-smartinput'


":Make cover for long-running tasks
NeoBundle 'tpope/vim-dispatch'
NeoBundleLazy 'tpope/vim-markdown', { 'autoload' : { 'filetypes' : [ 'markdown' ] } }

" VCS Integration
NeoBundle 'tpope/vim-fugitive', { 'augroup' : 'fugitive'}
" {{{ Fugitive hotkeys
" <leader>gs   Gstatus
"               D for diff
"               r for reload
" <leader>gl   Glog
" <leader>gd   Gdiff
" <leader>gw   Gwrite
" <leader>gb   Gblame
" }}} Fugitive hotkeys
NeoBundle 'tpope/vim-git'
NeoBundleLazy 'gregsexton/gitv', { 'depends' : [ 'tpope/vim-fugitive' ]
                               \ , 'autoload' : { 'commands' : 'Gitv' }
                               \ }
" {{{ GitV hotkeys
" \gv -> full repo view, \gV -> file view
" <cr> -> view commit, <C-n>/<C-p> jump to next/previous commit and <cr>.
" o -> <cr> with split, O -> tab, s -> vsplit
" co -> checkout
" S -> diffstat
" yc -> copy SHA
" x/X -> next/previous branching point
" Folds are enabled
" }}}

" ======================================

" View highlight groups under cursor
"NeoBundle 'gerw/vim-HiLinkTrace'    ", { \ 'lazy': 1, \}

" View relative line-numbers in operator-pending mode
"NeoBundle 'vim-scripts/RelOps'

" Change your root working dir to nearest .git on file_open or <Leader>cd
NeoBundle 'airblade/vim-rooter'
" The Silver searcher
NeoBundle 'rking/ag.vim', { 'external_commands' : 'ag' }
" ======================================

" Undo tree
NeoBundleLazy 'mbbill/undotree', { 'autoload' : { 'commands' : 'UndotreeToggle' } }

NeoBundleLazy 'godlygeek/tabular', { 'autoload' : { 'commands' : [ 'Tab', 'Tabularize' ] } }

NeoBundleLazy 'majutsushi/tagbar', { 'autoload' : { 'commands' : 'TagbarToggle' } }

NeoBundle 'tomtom/tcomment_vim'
" Alt: tpope/commentary

" NeoBundle

"{{{ Motions ============================
NeoBundle 'Lokaltog/vim-easymotion'
" Start with ,.

" New motions [count]{ ,w ,b ,e } for n/o/v modes in camel_case
NeoBundle 'bkad/CamelCaseMotion'

" Switch [c,cpp,cxx,cc] <-> [h,hpp]
NeoBundle 'vim-scripts/a.vim'

"{{{ Std vim/macros/ =====================
" Bring back opened window instead of dull msg about swapfile
"NeoBundle 'svintus/vim-editexisting'
"ERROR: conflicting

NeoBundle 'matchit.zip'
" NeoBundleLazy 'matchit.zip', { 'autoload' : {
"       \ 'mappings' : ['%', 'g%']
"       \ }}
" let bundle = neobundle#get('matchit.zip')
" function! bundle.hooks.on_post_source(bundle)
"   silent! execute 'doautocmd Filetype' &filetype
" endfunction
" }}} Std
"
" }}} Motions

" Alt: 'bb:abudden/taghighlight' "(small and fast) from bitbucket
"NeoBundle 'xolox/vim-easytags', { 'depends' : [ 'xolox/vim-misc' ] }
"NeoBundle 'xolox/vim-misc'
NeoBundle 'AndrewRadev/linediff.vim'



NeoBundle 'chrisbra/NrrwRgn'
" <leader>nr -> narrow region

NeoBundle 'depuracao/vim-rdoc'


NeoBundle 'lyokha/vim-xkbswitch', {
    \ 'autoload' :
    \   { 'filetypes' : [ 'tex', 'latex', 'bib'
                      \ , 'markdown'
                      \ , 'votl', 'txt'
                      \ ],
    \ 'commands' : 'EnableXkbSwitch'
    \   }
    \ , 'name' : 'vim-xkbswitch'
    \ }


" ======================================
NeoBundleLazy 'LaTeX-Box-Team/LaTeX-Box', {
\ 'autoload' : { 'filetypes' : [ 'tex', 'bib', 'latex' ] },
\ 'external_commands': [ 'latexmk' ],
\ }
" {{{ LaTeX-Box
" C-xC-o completion
" [[ -> \begin
" ]] -> \end / \right / whatever
" n-f5 -- */ no-*
" v-f7 -- wrap into command
" ([ -- eqref
" (( -- \left(
" )) -- \item
" }}} LaTeX-Box


" ======================================
"NeoBundle 'MPogoda/octave.vim--'
"NeoBundleLazy 'docunext/closetag.vim', { 'autoload' : { 'filetypes' : ['html', 'xml'] }
"                                     \ , 'name' : 'closetag'
"                                     \ }

" NeoBundle 'vim-scripts/DoxygenToolkit.vim'
NeoBundle 'hsanson/vim-android'
" Web
" NeoBundle 'mattn/emmet-vim'
" NeoBundle 'cakebaker/scss-syntax.vim'
" NeoBundle 'gorodinskiy/vim-coloresque'
" NeoBundle 'tpope/tpope/vim-unimpaired'

" Has syntastic integration, allow building CMake from vim.
" TODO: temporarily disabled as I can't understand how to integrate with syntastic
" NeoBundle 'jalcine/cmake.vim'

NeoBundle 'scrooloose/syntastic'
"NeoBundle 'scrooloose/nerdtree, { 'augroup' : 'NERDTreeHijackNetrw'}'

""" Ability to edit entries from qf or lc windows in new buffer
NeoBundle 'jceb/vim-editqf'

" Autoformatting with one button, can use custom (like clang-styler)
NeoBundle 'Chiel92/vim-autoformat'
" Auto-formatter for c/cpp/obj-c
NeoBundle 'rhysd/vim-clang-format'
" DEP BY: vim-clang-format
NeoBundle 'kana/vim-operator-user'

" Documentation online finder in one button for word under cursor
" Keithbsmiley/investigate.vim
" powerman/vim-plugin-viewdoc

NeoBundle 'octol/vim-cpp-enhanced-highlight'
" Syntax highlight
" https://github.com/Shirk/vim-gas
" https://github.com/beyondmarc/opengl.vim

" Highlight choosen
NeoBundle 't9md/vim-quickhl'


" Colorize html-codes
" NeoBundleLazy 'lilydjwg/colorizer'

" JSON Highlight and indent plugin
NeoBundleLazy 'elzr/vim-json', {
    \ 'autoload': { 'filetypes': [ 'json' ] },
    \}

"" For future of haskell
"NeoBundle 'lukerandall/haskellmode-vim' { 'autoload' : { 'filetypes' : ['haskell', 'hs'] }  }
" eagletmt/ghcmod-vim
" eagletmt/neco-ghc
" dag/vim2hs
" Twinside/vim-haskellConceal
"" Scala
" derekwyatt/vim-scala


" ======================================
"TIME:
NeoBundle 'bling/vim-airline'
" Alt: 'airblade/vim-gitgutter' "Only for git, but much faster file save
NeoBundle 'mhinz/vim-signify'
" Plugin to toggle, display and navigate marks
" NeoBundle 'kshenoy/vim-signature'

" DEPRECATED: use Unite MRU
" NeoBundle 'mhinz/vim-startify'

" When swap exists, it show process id, or you can diff swp with file on disk
NeoBundle 'chrisbra/Recover.vim'

"  toggle the plugin is <Leader>ig
NeoBundle 'nathanaelkane/vim-indent-guides'

" Substitution: {{{
" ALT: osyo-manga/vim-anzu
NeoBundle 'henrik/vim-indexed-search'
NeoBundle 'bronson/vim-visual-star-search'
" Multiple hl for searching by / ? or g/
NeoBundle 'haya14busa/incsearch.vim'
" :substitute preview
NeoBundle 'osyo-manga/vim-over'
" }}} ======================================


" ======================================
" Add new virtual cursor for next occurance of word under cursor
" Or add them for each line of multiline selection
" Ctrl-n  --> Ctrl-p, Ctrl-x, and <Esc>
NeoBundle 'kris89/vim-multiple-cursors'
NeoBundle 'terryma/vim-smooth-scroll'
" Press + to expand the visual selection  and _ to shrink it.
NeoBundle 'terryma/vim-expand-region'
" Move text (line or vselect) in more friendly way, then :m[ove]
NeoBundle 'matze/vim-move'

" ======================================

" Viewing man in vim: good, but no colors in git lg1, need to investigate
" NeoBundleLazy 'rkitover/vimpager'

" Fast table creation and modification
NeoBundle 'dhruvasagar/vim-table-mode'
" ALT: http://tiddlywiki.com  -- one-page wiki
NeoBundle 'vimoutliner/vimoutliner', {
    \ 'autoload' : { 'filetypes' : [ 'votl', 'txt' ], },
    \ }

" ======================================
" Colorschemes
" 'jnurmine/Zenburn' -- dark-brown, low-contract
"NeoBundle 'euclio/vim-nocturne',
NeoBundle 'tomasr/molokai'
NeoBundle 'noahfrederick/vim-hemisu'
NeoBundle 'altercation/vim-colors-solarized'
NeoBundle 'chriskempson/vim-tomorrow-theme'
