""" Python {{{1

call dein#add('hynek/vim-python-pep8-indent', {
  \ 'on_ft': 'python'})



"" [Syntax] (async linting) https://github.com/dense-analysis/ale
" DFL: ['flake8', 'mypy', 'pylint', 'pyright']
" VIZ:linters: ['bandit', 'flake8', 'jedils', 'mypy', 'prospector', 'pycodestyle', 'pydocstyle', 'pyflakes', 'pylama', 'pylint', 'pyls', 'pyre', 'pyright', 'vulture']
" VIZ:fixers: ['autoimport', ...
" ALSO: 'javascript': ['eslint'],
" TALK:(flake.vs.pylint): https://github.com/dense-analysis/ale/issues/3168 ⌇⡠⠍⣤⡵
" TALK:(fixers+=yapf): Why black over yapf? | Hacker News ⌇⡠⠍⣣⡖
"   https://news.ycombinator.com/item?id=17155048
" SEIZE:(linter status): https://www.vimfromscratch.com/articles/vim-for-python/
" TODO: pytest, nosetest, isort, black
" FAIL:(autoimport): moves imports outside conditions and above shebang
" \\n   let g:ale_python_pylint_use_msg_id = 1
call dein#add('dense-analysis/ale', {
  \ 'on_ft': 'python',
  \ 'on_cmd': ['ALEInfo', 'ALEFix'],
  \ 'hook_source': "
\\n   let g:ale_linters_explicit = 1
\\n   let g:ale_linters = { 'python': ['flake8', 'pylint'] }
\\n   let g:ale_python_pylint_options = '--disable=C0103,C0111,W0511'
\\n
\\n   let g:ale_fixers = { 'python': ['black', 'isort'] }
\\n   let g:ale_fix_on_save = 1
\\n   let g:ale_fix_on_save_ignore = { 'python': [] }
\"})



" BUG: update error
" on_cmd: Pyimport
call dein#add('davidhalter/jedi-vim', {
  \ 'on_ft': 'python',
  \ 'hook_source': _hcat('jedi-vim.src')})
" \\n   let g:jedi#goto_command = "<LocalLeader>d"
" \\n   let g:jedi#goto_assignments_command = "<LocalLeader>g"  " Declaration
" \\n   let g:jedi#rename_command = "<LocalLeader>r"
" \\n   let g:jedi#documentation_command = "<LocalLeader>k"
" \\n   let g:jedi#usages_command = "<LocalLeader>u"
" \\n   let g:jedi#goto_stubs_command = ""
" \'})



"" DISABLED: too much CPU load when editing
" mappings: [ [[, ]], [M, ]M, [ai]C, [ai]M ]
" \ 'rev': 'update_submodules',
" call dein#add('klen/python-mode', {
"   \ 'on_ft': 'python',
"   \ 'hook_source': _hcat('python-mode.src')})



"" [Colorize]
call dein#add('numirias/semshi', {
  \ 'on_ft': 'python'})



"" [Textobj] https://github.com/jeetsukumaran/vim-pythonsense
" ALT:OLD: https://github.com/bps/vim-textobj-python
"   USAGE: ..[ai][fc]  {[]}p[fc] -- next/prev func/class
call dein#add('jeetsukumaran/vim-pythonsense', {
  \ 'on_ft': 'python',
  \ 'hook_source': "
\\n   xmap <buffer><silent><unique> <LocalLeader>c <Plug>(PythonsenseOuterClassTextObject)
\\n   omap <buffer><silent><unique> <LocalLeader>c <Plug>(PythonsenseOuterClassTextObject)
\\n   xmap <buffer><silent><unique> <LocalLeader>C <Plug>(PythonsenseInnerClassTextObject)
\\n   omap <buffer><silent><unique> <LocalLeader>C <Plug>(PythonsenseInnerClassTextObject)
\\n
\\n   xmap <buffer><silent><unique> <LocalLeader>f <Plug>(PythonsenseOuterFunctionTextObject)
\\n   omap <buffer><silent><unique> <LocalLeader>f <Plug>(PythonsenseOuterFunctionTextObject)
\\n   xmap <buffer><silent><unique> <LocalLeader>F <Plug>(PythonsenseInnerFunctionTextObject)
\\n   omap <buffer><silent><unique> <LocalLeader>F <Plug>(PythonsenseInnerFunctionTextObject)
\\n
\\n   omap <buffer><silent><unique> <LocalLeader>d <Plug>(PythonsenseOuterDocStringTextObject)
\\n   xmap <buffer><silent><unique> <LocalLeader>d <Plug>(PythonsenseOuterDocStringTextObject)
\\n   omap <buffer><silent><unique> <LocalLeader>D <Plug>(PythonsenseInnerDocStringTextObject)
\\n   xmap <buffer><silent><unique> <LocalLeader>D <Plug>(PythonsenseInnerDocStringTextObject)
\"})



"" [Textobj] https://github.com/thalesmello/vim-textobj-multiline-str
" ALSO: https://codeinthehole.com/tips/vim-text-objects/
call dein#add('thalesmello/vim-textobj-multiline-str', {
  \ 'on_source': 'vim-operator-surround',
  \ 'on_ft': 'python',
  \ 'depends': 'vim-textobj-user',
  \ 'hook_source': "
\\n   let g:textobj_multilinestr_no_default_key_mappings = 1
\\n   xmap <buffer><silent><unique> <LocalLeader>q <Plug>(textobj-multilinestr-a)
\\n   omap <buffer><silent><unique> <LocalLeader>q <Plug>(textobj-multilinestr-a)
\\n   xmap <buffer><silent><unique> <LocalLeader>Q <Plug>(textobj-multilinestr-i)
\\n   omap <buffer><silent><unique> <LocalLeader>Q <Plug>(textobj-multilinestr-i)
\"})


"" [Textobj] jupyter cells FMT="# %%" ⌇⡠⠈⠏⡋
" https://github.com/GCBallesteros/vim-textobj-hydrogen


"" [REPL] ⌇⡠⠇⣹⣟
" OFF: https://github.com/wmvanvliet/jupyter-vim
" DEP: $ paci python-qtconsole jupyter_console
" ALT: https://github.com/hanschen/vim-ipython-cell
"   OLD: https://github.com/szymonmaszke/vimpyter
"   TUT:2019: https://towardsdatascience.com/boosting-your-data-science-workflow-with-vim-tmux-14505c5e016e
" \\n    noremap  <silent> <Plug>JupyterRunVisual     :<C-u>call <SID>opfunc_run_code(visualmode())<CR>gv
call dein#add('jupyter-vim/jupyter-vim', {
  \ 'on_ft': 'python',
  \ 'on_cmd': 'JupyterConnect',
  \ 'hook_source': "
\\n    let g:jupyter_mapkeys = 0
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>z :JupyterConnect<CR>
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>R :JupyterRunFile<CR>
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>I :PythonImportThisFile<CR>
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>X :JupyterSendCell<CR>
\\n
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>l :let b:p=getcurpos()\\|JupyterSendRange\\|call setpos('.',b:p)<CR>
\\n    xnoremap <buffer><silent><unique>  <LocalLeader>l :JupyterSendRange<CR>
\\n    nmap     <buffer><silent><unique>  <LocalLeader>e <Plug>JupyterRunTextObj
\\n    xmap     <buffer><silent><unique>  <LocalLeader>e <Plug>JupyterRunVisual
\\n    nmap     <buffer><silent><unique>  <LocalLeader>f <Plug>JupyterRunTextObj<Plug>(PythonsenseOuterFunctionTextObject)
\\n    nmap     <buffer><silent><unique>  <LocalLeader>c <Plug>JupyterRunTextObj<Plug>(PythonsenseOuterClassTextObject)
\\n    nmap     <buffer><silent><unique>  <LocalLeader>L <Plug>JupyterRunTextObj$
\\n
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>U :JupyterUpdateShell<CR>
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>b :PythonSetBreak<CR>
\"})



"" [Formatting]
call dein#add('psf/black', {
  \ 'on_ft': 'python',
  \ 'on_cmd': 'Black'})



"" [DEBUG] https://github.com/puremourning/vimspector
" CFG: :VimspectorInstall debugpy
" CFG: Setting up Vimspector | Vimspector ⌇⡠⠈⠬⣭
"   https://puremourning.github.io/vimspector-web/demo-setup.html
call dein#add('puremourning/vimspector', {
  \ 'on_ft': 'python',
  \ 'hook_source': "
\\n   let g:vimspector_enable_mappings = 'HUMAN'
\"})
