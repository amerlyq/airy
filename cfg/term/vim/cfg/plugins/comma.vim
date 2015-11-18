" Use ',' as leader for all plugins below

" Asynchronous execution plugin for Vim
" Must not be lazy for neobundle to use it to update plugins
NeoBundle 'Shougo/vimproc.vim', {
  \ 'lazy': 0,
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
NeoBundle 'Shougo/unite.vim', { 'depends' : 'Shougo/neomru.vim' }
NeoBundleLazy 'Shougo/unite-outline', { 'depends' : 'Shougo/unite.vim'
    \ , 'autoload' : { 'unite_sources' : 'outline' }}
NeoBundle 'Shougo/neomru.vim', { 'depends' : 'Shougo/unite.vim' }
" NeoBundleLazy 'thinca/vim-unite-history', { 'depends' : 'unite.vim'
"    \ , 'autoload' : { 'unite_sources' : 'history/command' 4}}


" ======================================
if IsWindows()
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
" ALT https://github.com/sjl/gundo.vim/
NeoBundleLazy 'mbbill/undotree', {
    \ 'autoload' : { 'commands' : 'UndotreeToggle' } }
NeoBundleLazy 'godlygeek/tabular', {
    \ 'autoload' : { 'commands' : [ 'Tab', 'Tabularize' ] } }
NeoBundleLazy 'majutsushi/tagbar', {
    \ 'autoload' : { 'commands' : 'TagbarToggle' } }



"{{{1 Std vim/macros/ =====================

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

" ======================================

" When swap exists, it show process id, or you can diff swp with file on disk
NeoBundle 'chrisbra/Recover.vim'

" }}} ======================================

NeoBundle 'amerlyq/vim-focus-autocmd'
" Viewing man in vim -- good, but no colors in git lg1, need to investigate
" NeoBundleLazy 'rkitover/vimpager'
