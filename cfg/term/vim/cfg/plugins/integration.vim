"{{{1 Apps ============================
" Ultimate hex-editing system (depends on hexript for some optional scripts)
"   (now that repo 'rbtnn/hexript.vim' don't exists?)
NeoBundle 'Shougo/vinarise.vim', { 'autoload': {
    \ 'commands' : ['Vinarise', 'VinariseDump'],
    \ 'explorer' : 1 }}

NeoBundle 'wmvanvliet/vim-ipython'
" NeoBundle 'wilywampa/vim-ipython'

" Use !dict translations from inside vim
NeoBundle 'szw/vim-dict'
" W3m from vim
"NeoBundle 'yuratomo/w3m.vim'
" Viewing man in vim -- good, but no colors in git lg1, need to investigate
" NeoBundleLazy 'rkitover/vimpager'


"{{{1 Services ============================
" No Lazy -- vim will pause 'ENTER' on file open
NeoBundle 'lyokha/vim-xkbswitch', { 'autoload' : {
    \ 'filetypes' : [ 'tex', 'latex', 'bib', 'markdown', 'votl', 'txt' ],
    \ 'commands' : 'EnableXkbSwitch'
    \ }, 'name' : 'vim-xkbswitch' }

NeoBundleLazy 'chrisbra/unicode.vim', { 'autoload': {
    \ 'commands': ['Digraphs', 'SearchUnicode', 'UnicodeName',
    \              'UnicodeTable', 'DownloadUnicode'],
    \ 'mappings': [['n', '<C-X><C-G>'], ['n', '<C-X><C-Z>'], ['n', '<F4>']] }}

" Documentation online finder in one button for word under cursor
" Keithbsmiley/investigate.vim
" powerman/vim-plugin-viewdoc
NeoBundle 'KabbAmine/zeavim.vim', { 'disabled' : !has('unix') }

" Edit and save encrypted *.gpg files 'in-place'
" BUG: can't do it lazy?
NeoBundle 'jamessan/vim-gnupg'


"{{{1 VCS ============================
NeoBundle 'tpope/vim-git'  " TODO: is this necessary? For which?
" Multiwindow regime for 'git commit [--amend]'
" NOTE seems like can't be loaded lazy?
" TRY more precisely SEE https://github.com/Shougo/neobundle.vim/issues/434
NeoBundleLazy 'rhysd/committia.vim', { 'autoload': {
    \ 'explorer': 'COMMIT_EDITMSG' }}

NeoBundle 'tpope/vim-fugitive', {'autoload': {
    \ 'augroup' : 'fugitive',
    \ 'commands' : [ 'Git', 'Gstatus', 'Gdiff', 'Glog', 'Gbrowse' ] }}

NeoBundleLazy 'gregsexton/gitv', { 'depends' : 'tpope/vim-fugitive',
    \ 'autoload' : { 'commands' : 'Gitv' }}
" \gv -> full repo view, \gV -> file view
" <cr>: view commit, <C-n/p>: jump to next/prev commit and <cr>.
" o: <cr> with split, O: tab, s: vsplit
" co: checkout, S: diffstat, yc: copy SHA
" x/X: next/previous branching point

" THINK
" 'lambdalisue/vim-gista', { 'autoload': {
"   \ commands = 'Gista', mappings = '<Plug>', unite_sources = 'gista' }}
" repository = 'lambdalisue/vim-gita'
