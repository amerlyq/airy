" C-^ should be used to leave the location list

let g:editqf_saveqf_filename  = "quickfix.list"
let g:editqf_saveloc_filename = "location.list"

" Jump to the edited error when editing finished:
let g:editqf_jump_to_error = 0

" Store absolute filename when adding a new note
let g:editqf_store_absolute_filename = 1

" The default keybinding <leader>n for adding a quickfix note can be
" customized by defining a mapping in your vimrc. Default must be disabled:
let g:editqf_no_mappings = 1

nmap <unique> [Frame]n <Plug>QFAddNote
nmap <unique> [Frame]N <Plug>QFAddNotePattern
" nmap <leader>l <Plug>LocAddNote
" nmap <leader>L <Plug>LocAddNotePattern


" The mappings [I,W,E] to change the type of quickfix entry can be turned off by setting:
" But << and >> had remained to cycle through types
let g:editqf_no_type_mappings = 1
