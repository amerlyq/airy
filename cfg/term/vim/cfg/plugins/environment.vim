"{{{1 Apps ============================

NeoBundle 'amerlyq/vim-focus-autocmd'

" When swap exists, it show process id, or you can diff swp with file on disk
NeoBundle 'chrisbra/Recover.vim'

" Change your root working dir to nearest .git on file_open or <Leader>cd
NeoBundleLazy 'airblade/vim-rooter', {'autoload': {'commands': 'Rooter'}}

" Switch [c,cpp,cxx,cc] <-> [h,hpp]
NeoBundle 'kana/vim-altr'
" , { 'autoload': {
"     \ 'commands' : 'A', 'mappings': '<Plug>(altr-' }}

" Open path/to/file:line from :e and by gF -- in more formats
NeoBundle 'kopischke/vim-fetch'
" View session auto create/restore on buffer edit, argdo, bufdo et al.
NeoBundle 'kopischke/vim-stay'

" OFF: messed up my mappings -- READ the doc how to
" Converts automatic folds into manual to reduce recomputation CPU load
" NeoBundle 'konfekt/FastFold'
