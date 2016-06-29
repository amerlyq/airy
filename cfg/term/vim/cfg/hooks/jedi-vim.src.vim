" ATTENTION:OFF: Because of neocomplete/deoplete:
"   Disable mappings, but allow omnifunc:
let g:jedi#completions_command = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#show_call_signatures = 0
let g:jedi#popup_select_first = 0

" In runtime you can use:
"   jedi#force_py_version_switch() OR jedi#force_py_version(py_version)
if !has('nvim') | let g:jedi#force_py_version = 3 | endif
let g:jedi#use_tabs_not_buffers = 0  " Prefer buffers over tabs
" let g:jedi#use_splits_not_buffers = "left"
let g:jedi#smart_auto_mappings = 0
let g:jedi#popup_on_dot = 1
let g:jedi#show_call_signatures = 2

"" Mappings
" inoremap <silent> <buffer> <C-N> <c-x><c-o>
let g:jedi#goto_command = "<LocalLeader>d"  "
let g:jedi#goto_assignments_command = "<LocalLeader>g"  " Declaration
let g:jedi#rename_command = "<LocalLeader>r"
let g:jedi#documentation_command = "<LocalLeader>k"
let g:jedi#usages_command = "<LocalLeader>u"
