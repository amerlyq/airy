"{{{1 Search/Substitute ============================

" The Silver searcher
NeoBundle 'rking/ag.vim', {
    \ 'external_commands' : 'ag',
    \ 'autoload': { 'commands' : [
    \   'Ag', 'AgAdd', 'AgBuffer', 'AgFile', 'AgFromSearch',
    \   'AgHelp', 'LAg', 'LAgAdd', 'LAgBuffer', 'LAgHelp'
    \ ], }, }

" Multiple hl for searching by / ? or g/
NeoBundle 'haya14busa/incsearch.vim'  ", 'incsearch-preload'
" DESIDE: Highlight choosen
NeoBundle 't9md/vim-quickhl'


" Smart highlight (don't do lazy -- I use it almost always)
NeoBundle 'haya14busa/vim-asterisk'
" Index for search results
NeoBundle 'osyo-manga/vim-anzu'
" Preview :substitute patterns
NeoBundle 'osyo-manga/vim-over', {
    \ 'autoload': { 'commands' : ['OverCommandLine'], }}


" Delete entries from qf/loc wdws (or edit them as text) and save to apply
" Useful for interactive replacing in many files found by :Ag, skiping needless.
NeoBundle 'stefandtw/quickfix-reflector.vim'
