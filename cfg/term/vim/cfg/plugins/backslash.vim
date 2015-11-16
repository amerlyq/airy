" vim:fdm=marker:fdl=1
"{{{1 Apps ============================

" Switch [c,cpp,cxx,cc] <-> [h,hpp]
NeoBundle 'kana/vim-altr'
" , { 'autoload': {
"     \ 'commands' : 'A', 'mappings': '<Plug>(altr-' }}

" Open path/to/file:line from :e and by gF -- in more formats
NeoBundle 'kopischke/vim-fetch'
" View session auto create/restore on buffer edit, argdo, bufdo et al.
NeoBundle 'kopischke/vim-stay'

NeoBundle 'Valloric/ListToggle'

"OFF: " Ascii graph drawing in vim
" NeoBundleLazy 'vim-scripts/DrawIt' , { 'autoload' : {
"     \ 'commands' : 'DrawIt', 'mappings' : '<Plug>DrawItStart' }}
