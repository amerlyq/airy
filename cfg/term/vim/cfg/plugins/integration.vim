"{{{1 Apps ============================
" Edit and save encrypted *.gpg files 'in-place'
" BUG: can't do it lazy?
NeoBundle 'jamessan/vim-gnupg'
" Use !dict translations from inside vim
NeoBundle 'szw/vim-dict'

" Documentation online finder in one button for word under cursor
" Keithbsmiley/investigate.vim
" powerman/vim-plugin-viewdoc
NeoBundle 'KabbAmine/zeavim.vim', { 'disabled' : !has('unix') }
