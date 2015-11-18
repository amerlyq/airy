"{{{1 Apps ============================
" Edit and save encrypted *.gpg files 'in-place'
" BUG: can't do it lazy?
NeoBundle 'jamessan/vim-gnupg'
" Use !dict translations from inside vim
NeoBundle 'szw/vim-dict'

" W3m from vim
"NeoBundle 'yuratomo/w3m.vim'

" Documentation online finder in one button for word under cursor
" Keithbsmiley/investigate.vim
" powerman/vim-plugin-viewdoc
NeoBundle 'KabbAmine/zeavim.vim', { 'disabled' : !has('unix') }

" Multiwindow regime for 'git commit [--amend]'
" NOTE seems like can't be loaded lazy?
" TRY more precisely SEE https://github.com/Shougo/neobundle.vim/issues/434
NeoBundleLazy 'rhysd/committia.vim', { 'autoload': {
    \ 'explorer': 'COMMIT_EDITMSG' }}

NeoBundleLazy 'chrisbra/unicode.vim', { 'autoload': {
    \ 'commands': ['Digraphs', 'SearchUnicode', 'UnicodeName',
    \              'UnicodeTable', 'DownloadUnicode'],
    \ 'mappings': [['n', '<C-X><C-G>'], ['n', '<C-X><C-Z>'], ['n', '<F4>']] }}


NeoBundle 'wmvanvliet/vim-ipython'
" NeoBundle 'wilywampa/vim-ipython'

" THINK
" 'lambdalisue/vim-gista', { 'autoload': {
"   \ commands = 'Gista', mappings = '<Plug>', unite_sources = 'gista' }}
" repository = 'lambdalisue/vim-gita'
