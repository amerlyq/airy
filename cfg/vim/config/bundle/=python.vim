" Jedi {{{
" If you need completion on Tab:
" USE: https://github.com/ervandew/supertab

" let g:jedi#auto_initialization = 0
" Because of neocomplete:
let g:jedi#popup_select_first = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#completions_enabled = 0

" If you are a person who likes to use VIM-buffers not tabs
let g:jedi#use_tabs_not_buffers = 0
" let g:jedi#use_splits_not_buffers = "left"
" let g:jedi#popup_on_dot = 0

" TRY: map ,j<*>
let g:jedi#goto_assignments_command = "<Leader>ja"
let g:jedi#goto_definitions_command = "<Leader>jd"
let g:jedi#documentation_command = "<Leader>jr"
let g:jedi#usages_command = "<Leader>ju"
let g:jedi#completions_command = "<C-Space>"
let g:jedi#rename_command = "<Leader>jr"
let g:jedi#show_call_signatures = "1"

" jedi.preload_module('os', 'sys', 'math', 'whatever_module_you_want')

" }}} Jedi


" Python-mode {{{

" Keys:
" K             Show python docs
" <Ctrl-Space>  Rope autocomplete
" <Ctrl-c>g     Rope goto definition
" <Ctrl-c>d     Rope show documentation
" <Ctrl-c>f     Rope find occurrences
" <Leader>b     Set, unset breakpoint (g:pymode_breakpoint enabled)
" [[            Jump on previous class or function (normal, visual, operator modes)
" ]]            Jump on next class or function (normal, visual, operator modes)
" [M            Jump on previous class or method (normal, visual, operator modes)
" ]M            Jump on next class or method (normal, visual, operator modes)


" Disabled because of better omni by 'Jedi'
let g:pymode_rope = 0
let g:pymode_rope_completion = 0
let g:pymode_rope_complete_on_dot = 0

" Documentation
let g:pymode_doc = 0
let g:pymode_doc_key = 'K'

" Linting (code checking)
let g:pymode_lint = 1
let g:pymode_lint_checker = "pyflakes,pep8"
" let g:pymode_lint_ignore="E501,W601,C0110"
" Auto check on save
let g:pymode_lint_write = 1

" Support virtualenv
let g:pymode_virtualenv = 1

" Enable breakpoints plugin
let g:pymode_breakpoint = 1
" inserts import pdb; pdb.set_trace() ### XXX BREAKPOINT into your code
let g:pymode_breakpoint_key = '<leader>b'

" syntax highlighting
let g:pymode_syntax = 1
let g:pymode_syntax_all = 1
let g:pymode_syntax_indent_errors = g:pymode_syntax_all
let g:pymode_syntax_space_errors = g:pymode_syntax_all

" Don't autofold code
let g:pymode_folding = 0
let g:pymode_run = 0

" }}} Rope


