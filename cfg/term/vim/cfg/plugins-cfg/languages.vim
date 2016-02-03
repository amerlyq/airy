if neobundle#tap('LaTeX-Box') "{{{
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/latex-box.vim'
  call neobundle#untap()
endif "}}}

if neobundle#tap('haskellmode-vim') "{{{
  let g:haddock_browser = "x-www-browser"
  call neobundle#untap()
endif "}}}


"{{{1 Python =============================
if neobundle#tap('jedi-vim') "{{{
  " ATTENTION:OFF: Because of neocomplete/deoplete:
  "   Disable mappings, but allow omnifunc:
  let g:jedi#completions_command = ""
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
  " Mappings
  " inoremap <silent> <buffer> <C-N> <c-x><c-o>
  let g:jedi#goto_command = "<LocalLeader>d"  "
  let g:jedi#goto_assignments_command = "<LocalLeader>g"  " Declaration
  let g:jedi#rename_command = "<localleader>r"
  let g:jedi#documentation_command = "<LocalLeader>k"
  let g:jedi#usages_command = "<LocalLeader>u"
  call neobundle#untap()
endif "}}}


if neobundle#tap('python-mode') "{{{
  " K             Show python docs
  " <C-Space>  Rope autocomplete
  " <C-c>g     Rope goto definition
  " <C-c>d     Rope show documentation
  " <C-c>f     Rope find occurrences
  " <Leader>b     Set, unset breakpoint (g:pymode_breakpoint enabled)
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
  call neobundle#untap()
endif "}}}


"{{{1 Mark-up =============================
if neobundle#tap('vimoutliner')  "{{{
  fun! neobundle#hooks.on_post_source(bundle)
    " Allows to create already [X] marks
    let s:cmd ='call SafelyInsertCheckBox() <Bar> call SwitchBox() <Bar>'
    if !exists('g:vo_checkbox_fast_calc') || g:vo_checkbox_fast_calc == 1
      let s:cmd .= 'call CalculateMyBranch(line("."))'
    else
      let s:cmd .= 'call NewHMD(FindRootParent(line(".")))'
    endif
    exe 'noremap <silent><buffer> <localleader>cX :'.s:cmd.'<CR>'
  endf
  call neobundle#untap()
endif "}}}
