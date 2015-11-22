finish
# vim: ft=yaml
## Env

amerlyq/vim-focus-autocmd:

chrisbra/Recover.vim:
  description: If swap exists -- allows to diff with swap, shows pid

" Change your root working dir to nearest .git on file_open or <Leader>cd
NeoBundleLazy 'airblade/vim-rooter', {'autoload': {'commands': 'Rooter'}}

" Switch [c,cpp,cxx,cc] <-> [h,hpp]
kana/vim-altr:
" , { 'autoload': {
"     \ 'commands' : 'A', 'mappings': '<Plug>(altr-' }}

" Open path/to/file:line from :e and by gF -- in more formats
kopischke/vim-fetch:
kopischke/vim-stay:
  description: session auto create/restore on buf edit, argdo, bufdo, etc

" OFF: messed up my mappings -- READ the doc how to
" Converts automatic folds into manual to reduce recomputation CPU load
" NeoBundle 'konfekt/FastFold'
