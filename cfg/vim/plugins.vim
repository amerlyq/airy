" vim:fdm=marker:fdl=1
" :NeoBundleClearCache if change .vimrc

let mapleader="\\"


" Switch [c,cpp,cxx,cc] <-> [h,hpp]
NeoBundle 'vim-scripts/a.vim'

NeoBundle 'Valloric/ListToggle'

" Ascii graph drawing in vim
NeoBundleLazy 'vim-scripts/DrawIt' , {
    \ 'autoload' : { 'commands' : 'DrawIt' },
    \ }

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

" TODO: there must be checking on mingw! Too many plugins depends on vimproc.
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

" Ultimate hex-editing system
" depends on hexript for some optional scripts
"   (now that repo 'rbtnn/hexript.vim' don't exists)
NeoBundle 'Shougo/vinarise.vim', {
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
NeoBundle 'Shougo/unite.vim', {
    \ 'name' : 'unite.vim'
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
    \ 'disabled' : !has('lua'),
    \ 'vim_version' : '7.3.885',
    \ 'depends' :
    \   [ 'Shougo/context_filetype.vim'
    \   , 'Shougo/vimproc.vim'
    \   ],
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
else

"ONLY FOR WIN: on unix use snip-ranger-filechooser.vim
NeoBundleLazy 'Shougo/vimfiler', {
    \ 'depends' : 'Shougo/unite.vim',
    \ 'autoload' : {
    \    'commands' : [{ 'name' : 'VimFiler',
    \                    'complete' : 'customlist,vimfiler#complete' },
    \                  'VimFilerExplorer',
    \                  'Edit', 'Read', 'Source', 'Write'],
    \    'mappings' : ['<Plug>(vimfiler_'],
    \    'explorer' : 1,
    \ }}

endif



"" Python =======================

" Temporary disabled. Reported it has perfomance troubles with Jedi.
NeoBundle 'klen/python-mode', {
    \ 'autoload' : { 'filetypes' : [ 'python' ] } }
NeoBundle 'davidhalter/jedi-vim', {
    \ 'autoload' : { 'filetypes' : [ 'python' ] } }
NeoBundle 'joonty/vdebug', {
    \ 'autoload' : { 'filetypes' : [ 'python' ] } }


" ======================================
" Readline style insertion
" http://www.vim.org/scripts/script.php?script_id=4359
NeoBundle 'tpope/vim-rsi'
" Automatic not-persistent closing statements
NeoBundle 'tpope/vim-endwise'
" Extend support for '.' command
NeoBundle 'tpope/vim-repeat'
" Manage surrounding ('"<p>...) by replace cs"' or delete ds"
NeoBundle 'tpope/vim-surround'
" Use CTRL-A/X to increment dates, times, and more
NeoBundle 'tpope/vim-speeddating'
" Manage function arguments with textobj 'a,' 'i,', shifting with '<,' '>,'
" NeoBundle 'PeterRincker/vim-argumentative'
" Manage function arguments with textobj 'a,' 'i,', shifting with '<,' '>,'
NeoBundle 'AndrewRadev/sideways.vim'
" Exchange text: cx{motion} on first, then cx{motion} on other.
"   cxx -- current line, X -- Visual mode,  cxc -- clear pending exchange.
NeoBundle 'tommcdo/vim-exchange'

" DEPEND BY: vim-clang-format
NeoBundle 'kana/vim-operator-user'
" Function object (af, if -- code inside, aF -- all with spaces, iF )
NeoBundle 'kana/vim-textobj-function', { 'depends' : 'kana/vim-textobj-user' }
NeoBundle 'kana/vim-textobj-indent'
NeoBundle 'kana/vim-textobj-entire'
NeoBundle 'coderifous/textobj-word-column.vim'

" DISABLED: has problems with russian text
" Insert mode auto-completion for quotes, parens, brackets, etc
"NeoBundle 'Raimondi/delimitMate'
" DISABLED: bug with neocomplete -- <BS> don't remove both brackets,
" unnecessary quotes for my workflow, partially superseeded by vim-surround
"NeoBundle 'kana/vim-smartinput'


":Make cover for long-running tasks asynchronous (as like by ssh)
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
" ======================================

" Undo tree
NeoBundleLazy 'mbbill/undotree', { 'autoload' : { 'commands' : 'UndotreeToggle' } }

NeoBundleLazy 'godlygeek/tabular', { 'autoload' : { 'commands' : [ 'Tab', 'Tabularize' ] } }

NeoBundleLazy 'majutsushi/tagbar', { 'autoload' : { 'commands' : 'TagbarToggle' } }

NeoBundle 'tomtom/tcomment_vim'
" Alt: tpope/commentary

" NeoBundle

"{{{ Motions ============================
NeoBundle 'justinmk/vim-sneak'
" New motions [count]{ ,w ,b ,e } for n/o/v modes in camel_case
NeoBundle 'bkad/CamelCaseMotion'

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

NeoBundle 'scrooloose/syntastic'
"NeoBundle 'scrooloose/nerdtree, { 'augroup' : 'NERDTreeHijackNetrw'}'

""" Ability to edit entries from qf or lc windows in new buffer
" TRY ALT: quickfix-reflector.vim (http://www.vim.org/scripts/script.php?script_id=4890)
" ALT: https://github.com/thinca/vim-qfreplace
NeoBundleLazy 'jceb/vim-editqf', { 'autoload' : { 'commands' :
            \ ['QFEdit', 'QFAddNote', 'QFAddPatternNote'] } }



" Autoformatting with one button, can use custom (like clang-styler)
NeoBundle 'Chiel92/vim-autoformat'
" Auto-formatter for c/cpp/obj-c
NeoBundle 'rhysd/vim-clang-format'

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


" ======================================
"TIME:
NeoBundle 'bling/vim-airline'
" Alt: 'airblade/vim-gitgutter' "Only for git, but much faster file save
NeoBundle 'mhinz/vim-signify'
" Plugin to toggle, display and navigate marks
" NeoBundle 'kshenoy/vim-signature'

" When swap exists, it show process id, or you can diff swp with file on disk
NeoBundle 'chrisbra/Recover.vim'

"  toggle the plugin is <Leader>ig
NeoBundle 'nathanaelkane/vim-indent-guides'

" Substitution: {{{
" The Silver searcher
NeoBundle 'rking/ag.vim', {
    \ 'external_commands' : 'ag',
    \ 'autoload': { 'commands' : [
    \   'Ag', 'AgAdd', 'AgBuffer', 'AgFile', 'AgFromSearch',
    \   'AgHelp', 'LAg', 'LAgAdd', 'LAgBuffer', 'LAgHelp'
    \ ], }, }
" Multiple hl for searching by / ? or g/
NeoBundle 'haya14busa/incsearch.vim'
" Smart highlight
NeoBundleLazy 'haya14busa/vim-asterisk', {
    \   'autoload' : {
    \     'mappings' : ['<Plug>(asterisk-']
    \   }
    \ }
" Index for search results
NeoBundle 'osyo-manga/vim-anzu'
" Preview :substitute patterns
NeoBundle 'osyo-manga/vim-over', {
    \ 'autoload': { 'commands' : ['OverCommandLine'], },
    \ }

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
NeoBundleLazy 'matze/vim-move', { 'gui' : 1, }

" ======================================

" Viewing man in vim: good, but no colors in git lg1, need to investigate
" NeoBundleLazy 'rkitover/vimpager'

" Fast table creation and modification
NeoBundleLazy 'dhruvasagar/vim-table-mode', {
    \ 'autoload': { 'commands' : ['TableModeEnable'], },
    \ }

" ALT: http://tiddlywiki.com  -- one-page wiki
NeoBundleLazy 'vimoutliner/vimoutliner', {
    \ 'autoload' : { 'filetypes' : [ 'votl', 'txt' ], },
    \ }

NeoBundleLazy 'neilagabriel/vim-geeknote', {
    \ 'vim_version': '7.4.364',
    \ 'autoload': { 'commands' : ['Geeknote'], },
    \ }

" ======================================
" Colorschemes
" NeoBundle 'tomasr/molokai'
NeoBundle 'altercation/vim-colors-solarized'
