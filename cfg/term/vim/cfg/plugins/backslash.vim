" vim:fdm=marker:fdl=1
" USE '\' as <Leader> for all plugins below

let mapleader="\\"
noremap <unique> <Leader> <Nop>


" Switch [c,cpp,cxx,cc] <-> [h,hpp]
NeoBundle 'kana/vim-altr'
" , { 'autoload': {
"     \ 'commands' : 'A', 'mappings': '<Plug>(altr-' }}

NeoBundle 'Valloric/ListToggle'

"OFF: " Ascii graph drawing in vim
" NeoBundleLazy 'vim-scripts/DrawIt' , { 'autoload' : {
"     \ 'commands' : 'DrawIt', 'mappings' : '<Plug>DrawItStart' }}
