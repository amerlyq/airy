" vim:fdm=marker:fdl=1
" Jedi {{{1
" If you need completion on Tab:
" USE: https://github.com/ervandew/supertab

let g:jedi#force_py_version = 3
let g:jedi#auto_initialization = 1
" Because of neocomplete:
let g:jedi#completions_enabled = 0
let g:jedi#auto_vim_configuration = 0
let g:jedi#show_call_signatures = 0
let g:jedi#popup_select_first = 0
" ALT 'after': autocmd FileType python setlocal omnifunc=jedi#completions

" If you are a person who likes to use VIM-buffers not tabs
let g:jedi#use_tabs_not_buffers = 0
" let g:jedi#use_splits_not_buffers = "left"
" let g:jedi#popup_on_dot = 0

" TRY: map ,j<*>
let g:jedi#smart_auto_mappings = 0
let g:jedi#goto_command = "<LocalLeader>d"
let g:jedi#goto_assignments_command = "<LocalLeader>g"
let g:jedi#rename_command = "<localleader>r"
let g:jedi#documentation_command = "<LocalLeader>k"
let g:jedi#usages_command = "<LocalLeader>u"
let g:jedi#completions_command = "<C-Space>"

" jedi.preload_module('os', 'sys', 'math', 'whatever_module_you_want')



" Python-mode {{{1

" Keys:
" K             Show python docs
" <Ctrl-Space>  Rope autocomplete
" <Ctrl-c>g     Rope goto definition
" <Ctrl-c>d     Rope show documentation
" <Ctrl-c>f     Rope find occurrences
" <Leader>b     Set, unset breakpoint (g:pymode_breakpoint enabled)

let g:pymode_motion = 1
"| [[ | Jump to previous class or function
"| ]] | Jump to next class or function
"| [M | Jump to previous class or method
"| ]M | Jump to next class or method
"| aC | Select a class. Ex: vaC, daC, yaC, caC
"| iC | Select inner class. Ex: viC, diC, yiC, ciC
"| aM | Select a function or method. Ex: vaM, daM, yaM, caM
"| iM | Select inner function or method. Ex: viM, diM, yiM, ciM


" Don't autofold code
let g:pymode_folding = 1
" :PymodeRun -- run current buffer or _selection_
let g:pymode_run = 0
" let g:pymode_run_bind = '<leader>jr'

" Disabled because of better omni by 'Jedi'
let g:pymode_rope = 0
let g:pymode_rope_completion = 0
let g:pymode_rope_complete_on_dot = 0

" Documentation  :PymodeDoc <args> -- can't change default key
let g:pymode_doc = 0
" let g:pymode_doc_key = '<leader>jk'

" Support virtualenv  :PymodeVirtualenv <rel_path> -- activate it
let g:pymode_virtualenv = 1

" Enable breakpoints plugin
let g:pymode_breakpoint = 1
"" XXX BREAKPOINT into your code
" At begin, insert (pdb, ipdb, pudb): import pdb; pdb.set_trace()
let g:pymode_breakpoint_bind = '<LocalLeader>b'
" Manually set breakpoint command (leave empty for automatic detection)
let g:pymode_breakpoint_cmd = 'import ipdb; ipdb.set_trace()'


" syntax highlighting
let g:pymode_syntax = 1
let g:pymode_syntax_all = 1
let g:pymode_syntax_indent_errors = g:pymode_syntax_all
let g:pymode_syntax_space_errors = g:pymode_syntax_all



" Linting (code checking)
let g:pymode_lint = 1
" From: pylint, pep8, mccabe, pep257, pyflakes.
let g:pymode_lint_checker = "pylint,pep8"
let g:pymode_lint_ignore="E266,E501"
"E266,E501 -- multiple '#' in comments and line width > 80
"W391 -- empty line at EOF, better keep it enabled for fluent git auto-merge
"W601,C0110

" Auto open cwindow (quickfix) if any errors have been found
let g:pymode_lint_cwindow = 1
let g:pymode_lint_signs = 1


" Auto check on save
let g:pymode_lint_write = 0

" let g:pymode_lint_options_pep8 =
"     \ {'max_line_length': g:pymode_options_max_line_length})
" let g:pymode_lint_options_pylint =
"     \ {'max-line-length': g:pymode_options_max_line_length})
"}}}


" Vdebug {{{
" Depends on http://code.activestate.com/komodo/remotedebugging/
" Maped permanently only "run":<F5> and "set_breakpoint":<F10>.
" All others are mapped only while Vdebug is run, restoring origin on stop.
" To stop debugging, press <F6>. Press again to close the dbg interface.
" Run: :Vdebug in one window, and then $ make vdbg in another
" curl 'http://code.activestate.com/komodo/remotedebugging/' | sed -n '/.*\(Komodo-PythonRemoteDebugging-.*-linux-x86_64\.tar\.gz\).*/{p;q}'
let g:vdebug_keymap = {
    \    "run" : "<F5>",
    \    "run_to_cursor" : "<F1>",
    \    "step_over" : "<F2>",
    \    "step_into" : "<F3>",
    \    "step_out" : "<F4>",
    \    "close" : "<F6>",
    \    "detach" : "<F7>",
    \    "set_breakpoint" : "<F10>",
    \    "get_context" : "<F11>",
    \    "eval_under_cursor" : "<F12>",
    \    "eval_visual" : "\e",
    \ }
" let g:vdebug_features['max_depth'] = 2048
" }}}
