" K             Show python docs
" <C-Space>  Rope autocomplete
" <C-c>g     Rope goto definition
" <C-c>d     Rope show documentation
" <C-c>f     Rope find occurrences
" <Leader>b     Set, unset breakpoint (g:pymode_breakpoint enabled)
let g:pymode_python = 'python3'  " NOTE: must be set for 'yield from'
let g:pymode_options = 0
let g:pymode_trim_whitespaces = 0

let g:pymode_folding = 1  " Don't autofold code
let g:pymode_motion = 1

" :PymodeRun -- run current buffer or _selection_
let g:pymode_run = 0
let g:pymode_run_bind = '<LocalLeader>R'
" BUG: :PymodeDoc <args> -- can't change default key
let g:pymode_doc = 0
let g:pymode_doc_key = '<leader>K'

" Disabled because of better omni by 'Jedi'
let g:pymode_rope = 0
let g:pymode_rope_completion = 0
let g:pymode_rope_complete_on_dot = 0

" Support virtualenv  :PymodeVirtualenv <rel_path> -- activate it
let g:pymode_virtualenv = 1

" Enable breakpoints plugin
let g:pymode_breakpoint = 1  " XXX BREAKPOINT into your code
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
" let g:pymode_lint_checker = "pylint,pep8"
let g:pymode_lint_checkers = ['pyflakes', 'pep8']
let g:pymode_lint_ignore="E266,E501,W0401,E221"
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
