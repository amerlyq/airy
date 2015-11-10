" vim:fdm=marker:fdl=1
" Use ',' as leader for all plugins below

" Asynchronous execution plugin for Vim
NeoBundle 'Shougo/vimproc.vim', {
    \ 'external_commands' : 'make',
    \ 'build' : {
    \     'windows' : 'tools\\update-dll-mingw',
    \     'cygwin' : 'make -f make_cygwin.mak',
    \     'mac' : 'make -f make_mac.mak',
    \     'linux' : 'make',
    \     'unix' : 'gmake',
    \ }}

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
NeoBundle 'Shougo/vinarise.vim', { 'autoload': {
    \ 'commands' : ['Vinarise', 'VinariseDump'],
    \ 'explorer' : 1 }}


" Super-mega-replace for bunch of plugins
" See: http://bling.github.io/blog/2013/06/02/unite-dot-vim-the-plugin-you-didnt-know-you-need/
NeoBundle 'Shougo/unite.vim', { 'depends' : 'Shougo/vimproc.vim' }
NeoBundleLazy 'Shougo/unite-outline', { 'depends' : 'Shougo/unite.vim'
    \ , 'autoload' : { 'unite_sources' : 'outline' }}
NeoBundle 'Shougo/neomru.vim', { 'depends' : 'Shougo/unite.vim' }
" NeoBundleLazy 'thinca/vim-unite-history', { 'depends' : 'unite.vim'
"    \ , 'autoload' : { 'unite_sources' : 'history/command' 4}}


" ======================================
" Integration with neocomplete: for stdlib++, boost, etc (works on Windows)
" http://www.reddit.com/r/vim/comments/1x4mvg/vimmarching_with_neocomplete_doesnt_complete_c/
NeoBundle 'osyo-manga/vim-marching', { 'depends' : 'Shougo/vimproc.vim' }

" echo neobundle#tap('YouCompleteMe')

NeoBundleLazy 'Shougo/neocomplete.vim', {
    \ 'autoload' : { 'insert' : 1 },
    \ 'depends' : [
    \   'Shougo/context_filetype.vim',
    \   'Shougo/vimproc.vim' ],
    \ 'disabled' : !has('lua'),
    \ 'vim_version' : '7.3.885'}

" SirVer/ultisnips
NeoBundleLazy 'Shougo/neosnippet.vim', {
    \ 'autoload' : { 'insert' : 1 },
    \ 'depends' : [
    \   'Shougo/neocomplete.vim',
    \   'Shougo/neosnippet-snippets',
    \   'honza/vim-snippets' ],
    \ 'disabled' : !has('lua'),
    \ 'vim_version': '7.3.885'}


" ======================================

if has('unix')
    " W3m from vim
    "NeoBundle 'yuratomo/w3m.vim'

    "Lazy loading like this
    "NeoBundleLazy 'Rip-Rip/clang_complete'
    "autocmd FileType c,cpp NeoBundleSource clang_complete

    " "" Autocompletion for Python and C-like languages. Need Python2 exclusively
    " NeoBundleLazy 'Valloric/YouCompleteMe', {
    "     \ 'augroup': 'youcompletemeStart',
    "     \ 'autoload': {
    "     \   'commands' : ['YcmDebugInfo'],
    "     \   'filetypes' : [ 'c', 'cpp' ],
    "     \ },
    "     \ 'build': {
    "     \   'linux': './install.sh --clang-completer',
    "     \ },
    "     \ 'disabled': !has('python'),
    "     \ 'vim_version': '7.3.584',
    "     \ }
    "     " \   'unix': './install.sh --clang-completer --system-libclang'

    " TODO FIX: resolve completion conflicts -- seems like isn't disabled?
    " autocmd FileType c,cpp if exists(':YcmCompleter') | NeoCompleteDisable | endif
    " neocomplete: 'autoload': { 'filetypes' : [ 'vim', 'sh', 'shell', 'votl' ], },

" {{{Build instruction for YCM : if [ ! -e './third_party/ycmd/ycm_core.so' ]
"   1. git submodule update --init --recursive
"   2. cd third_party/ycmd && mkdir -p build && cd build && cmake .. ../cpp
"   5a. (optional) ccmake . # configure
"   6. make
" For win: https://github.com/Valloric/YouCompleteMe/wiki/Windows-Installation-Guide
" }}}

else

" In unix terminal use snip-ranger-filechooser.vim
NeoBundleLazy 'Shougo/vimfiler.vim', {
    \ 'depends' : 'Shougo/unite.vim',
    \ 'disabled' : has('unix') && !has('gui_running'),
    \ 'autoload' : {
    \    'commands' : [{ 'name' : 'VimFiler',
    \                    'complete' : 'customlist,vimfiler#complete' },
    \                  'VimFilerExplorer',
    \                  'Edit', 'Read', 'Source', 'Write'],
    \    'mappings' : ['<Plug>(vimfiler_'],
    \    'explorer' : 1,
    \ }}

endif

" ======================================
":Make cover for long-running tasks asynchronous (as like by ssh)
NeoBundle 'tpope/vim-dispatch'

" VCS Integration
NeoBundle 'tpope/vim-git'
NeoBundle 'tpope/vim-fugitive', {'autoload': {
    \ 'augroup' : 'fugitive',
    \ 'commands' : [ 'Git', 'Gstatus', 'Gdiff', 'Glog', 'Gbrowse' ] }}
NeoBundleLazy 'gregsexton/gitv', { 'depends' : 'tpope/vim-fugitive',
    \ 'autoload' : { 'commands' : 'Gitv' }}
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
NeoBundleLazy 'airblade/vim-rooter', {'autoload': {'commands': 'Rooter'}}
" ======================================

" Undo tree
NeoBundleLazy 'mbbill/undotree', {
    \ 'autoload' : { 'commands' : 'UndotreeToggle' } }
NeoBundleLazy 'godlygeek/tabular', {
    \ 'autoload' : { 'commands' : [ 'Tab', 'Tabularize' ] } }
NeoBundleLazy 'majutsushi/tagbar', {
    \ 'autoload' : { 'commands' : 'TagbarToggle' } }



"{{{1 Std vim/macros/ =====================
" Bring back opened window instead of dull msg about swapfile
"NeoBundle 'svintus/vim-editexisting'
"ERROR: conflicting
NeoBundle 'matchit.zip'

" Alt: 'bb:abudden/taghighlight' "(small and fast) from bitbucket
" NOTE: easytags can make CursorMove very slow
"   https://github.com/xolox/vim-easytags/issues/68#issuecomment-28480981
"NeoBundle 'xolox/vim-easytags', { 'depends' : [ 'xolox/vim-misc' ] }
"NeoBundle 'xolox/vim-misc'

" Focus on line/selection/window in new buffer. ALT to LineDiff?
NeoBundleLazy 'chrisbra/NrrwRgn' , { 'autoload' : {
    \ 'commands' : ['NR', 'NW', 'NRV', 'NUD', 'NRP', 'NRM', 'NRL'],
    \ 'mappings' : ['<Plug>NrrwrgnDo', '<Plug>NrrwrgnBangDo'],
    \ }}

NeoBundle 'AndrewRadev/linediff.vim'

" No Lazy -- vim will pause 'ENTER' on file open
NeoBundle 'lyokha/vim-xkbswitch', { 'autoload' : {
    \ 'filetypes' : [ 'tex', 'latex', 'bib', 'markdown', 'votl', 'txt' ],
    \ 'commands' : 'EnableXkbSwitch'
    \ }, 'name' : 'vim-xkbswitch' }


" ======================================

"NeoBundleLazy 'docunext/closetag.vim', {
"   \ 'autoload' : { 'filetypes' : ['html', 'xml'] } }
" NeoBundle 'vim-scripts/DoxygenToolkit.vim'
" NeoBundle 'hsanson/vim-android'
" Web
" NeoBundle 'mattn/emmet-vim'
" NeoBundle 'cakebaker/scss-syntax.vim'
" NeoBundle 'gorodinskiy/vim-coloresque'

NeoBundle 'scrooloose/syntastic'

" Autoformatting with one button, can use custom (like clang-styler)
NeoBundle 'Chiel92/vim-autoformat'
" Auto-formatter for c/cpp/obj-c
NeoBundle 'rhysd/vim-clang-format'



" JSON Highlight and indent plugin
NeoBundleLazy 'elzr/vim-json', {
    \ 'autoload': { 'filetypes': [ 'json' ] },
    \}

" ======================================

" When swap exists, it show process id, or you can diff swp with file on disk
NeoBundle 'chrisbra/Recover.vim'

" }}} ======================================

NeoBundle 'amerlyq/vim-focus-autocmd'
NeoBundleLazy 'amerlyq/vim-forestanza', {
    \ 'autoload' : { 'filetypes': 'forestanza' }}
" Viewing man in vim: good, but no colors in git lg1, need to investigate
" NeoBundleLazy 'rkitover/vimpager'
