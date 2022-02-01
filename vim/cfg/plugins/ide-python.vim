""" Python {{{1

call dein#add('hynek/vim-python-pep8-indent', {
  \ 'on_ft': 'python'})



"" [Syntax] (async linting) https://github.com/dense-analysis/ale
" DFL: ['flake8', 'mypy', 'pylint', 'pyright']
"   NICE:(pyright):PERF=5x(mypy) BUT:BAD:DEP=nodejs
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
\\n   let g:ale_linters = { 'python': ['flake8', 'mypy', 'pylint'] }
\\n   let g:ale_python_pylint_options = '--disable=C0103,C0111,W0511'
\\n   let g:ale_python_mypy_ignore_invalid_syntax = 1
\\n   let g:ale_python_mypy_options = ''
\\n
\\n   let g:ale_fixers = { 'python': ['isort', 'black'] }
\\n   let g:ale_fix_on_save = 1
\\n   let g:ale_fix_on_save_ignore = { 'python': ['autoimport'] }
\\n   let g:ale_completion_autoimport = 1
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
" TRY:ALT: https://github.com/nvim-treesitter/nvim-treesitter
" FIXED:ERR: lost hi on write SRC https://github.com/numirias/semshi/issues/54
"   BAD: hi disappears on async complete, not on the write
"   FIXED: chain highlight after auto-fix by ALE (e.g. from "!black")
" ALSO:(python=3.10): match-case :: https://github.com/cyyever/semshi
call dein#add('numirias/semshi', {
  \ 'on_ft': 'python',
  \ 'depends': 'ale',
  \ 'hook_source': "
\\n  augroup AleSemshi | augroup END
\\n  autocmd! AleSemshi User ALEFixPost Semshi highlight
\"})



"" [Textobj] https://github.com/jeetsukumaran/vim-pythonsense
" ALT:OLD: https://github.com/bps/vim-textobj-python
"   USAGE: ..[ai][fc]  {[]}p[fc] -- next/prev func/class
call dein#add('jeetsukumaran/vim-pythonsense', {
  \ 'on_ft': 'python',
  \ 'hook_source': "
\\n  autocmd MyAutoCmd FileType python call BufMap_vim_pythonsense()
\\n fun! BufMap_vim_pythonsense() abort
\\n   if exists('b:BufMap_vim_pythonsense')|return|else|let b:BufMap_vim_pythonsense=1|endif
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
\\n endf
\"})



"" [Textobj] https://github.com/thalesmello/vim-textobj-multiline-str
" ALSO: https://codeinthehole.com/tips/vim-text-objects/
call dein#add('thalesmello/vim-textobj-multiline-str', {
  \ 'on_source': 'vim-operator-surround',
  \ 'on_ft': 'python',
  \ 'depends': 'vim-textobj-user',
  \ 'hook_source': "
\\n   let g:textobj_multilinestr_no_default_key_mappings = 1
\\n   autocmd MyAutoCmd FileType python call BufMap_vim_textobj_multiline_str()
\\n  fun! BufMap_vim_textobj_multiline_str() abort
\\n   if exists('b:BufMap_vim_textobj_multiline_str')|return|else|let b:BufMap_vim_textobj_multiline_str=1|endif
\\n   xmap <buffer><silent><unique> <LocalLeader>q <Plug>(textobj-multilinestr-a)
\\n   omap <buffer><silent><unique> <LocalLeader>q <Plug>(textobj-multilinestr-a)
\\n   xmap <buffer><silent><unique> <LocalLeader>Q <Plug>(textobj-multilinestr-i)
\\n   omap <buffer><silent><unique> <LocalLeader>Q <Plug>(textobj-multilinestr-i)
\\n  endf
\"})


"" [Textobj] jupyter cells FMT="# %%" ⌇⡠⠈⠏⡋
" https://github.com/GCBallesteros/vim-textobj-hydrogen


"" [REPL] ⌇⡠⠇⣹⣟
" OFF: https://github.com/wmvanvliet/jupyter-vim
" DEP: $ paci python-qtconsole jupyter_console
" ALT: https://github.com/hanschen/vim-ipython-cell
"   OLD: https://github.com/szymonmaszke/vimpyter
"   TUT:2019: https://towardsdatascience.com/boosting-your-data-science-workflow-with-vim-tmux-14505c5e016e
" FIXME: open second file -- no mappings until ":JupyterConnect"
call dein#add('jupyter-vim/jupyter-vim', {
  \ 'on_ft': 'python',
  \ 'on_cmd': 'JupyterConnect',
  \ 'hook_source': _hcat('jupyter-vim.src')
\})



"" [Formatting]
call dein#add('psf/black', {
  \ 'on_ft': 'python',
  \ 'on_cmd': 'Black'})



"" [DEBUG] https://github.com/puremourning/vimspector
" CFG: :VimspectorInstall debugpy
" CFG: Setting up Vimspector | Vimspector ⌇⡠⠈⠬⣭
"   https://puremourning.github.io/vimspector-web/demo-setup.html
"" LIOR: \\n   let g:vimspector_enable_mappings = 'HUMAN'
" | F5   | <Plug>VimspectorContinue
" | F3   | <Plug>VimspectorStop
" | F4   | <Plug>VimspectorRestart
" | F6   | <Plug>VimspectorPause
" | F9   | <Plug>VimspectorToggleBreakpoint
" | L-F9 | <Plug>VimspectorToggleConditionalBreakpoint
" | F8   | <Plug>VimspectorAddFunctionBreakpoint
" | L-F8 | <Plug>VimspectorRunToCursor
" | F10  | <Plug>VimspectorStepOver
" | F11  | <Plug>VimspectorStepInto
" | F12  | <Plug>VimspectorStepOut
call dein#add('puremourning/vimspector', {
  \ 'on_ft': 'python',
  \ 'hook_source': "
\\n   let g:vimspector_enable_mappings = ''
\\n   nnoremap <buffer><silent><unique>  <LocalLeader>vg :VimspectorToggleLog<CR>
\\n   nnoremap <buffer><silent><unique>  <LocalLeader>vG :VimspectorDebugInfo<CR>
\\n
\\n   nmap     <buffer><silent><unique>  <LocalLeader>w <Plug>VimspectorBalloonEval
\\n   xmap     <buffer><silent><unique>  <LocalLeader>w <Plug>VimspectorBalloonEval
\\n
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vb <Plug>VimspectorToggleBreakpoint
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vB <Plug>VimspectorToggleConditionalBreakpoint
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vf <Plug>VimspectorAddFunctionBreakpoint
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vc <Plug>VimspectorContinue
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vh <Plug>VimspectorRunToCursor
\\n
\\n   nnoremap <buffer><silent><unique>  <LocalLeader>va :call vimspector#LaunchWithSettings({'configuration':'attach'})<CR>
\\n   nnoremap <buffer><silent><unique>  <LocalLeader>ve :call vimspector#LaunchWithSettings({'configuration':'run'})<CR>
\\n   nnoremap <buffer><silent><unique>  <LocalLeader>vr :call vimspector#LaunchWithSettings({'configuration':'run','StopOnEntry':1})<CR>
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vL <Plug>VimspectorLaunch
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vp <Plug>VimspectorPause
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vq <Plug>VimspectorStop
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vR <Plug>VimspectorRestart
\\n   nnoremap <buffer><silent><unique>  <LocalLeader>vx :VimspectorReset<CR>
\\n
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vn <Plug>VimspectorStepOver
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vi <Plug>VimspectorStepInto
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vs <Plug>VimspectorStepOver
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vS <Plug>VimspectorStepInto
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vo <Plug>VimspectorStepOut
\\n
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vj <Plug>VimspectorDownFrame
\\n   nmap     <buffer><silent><unique>  <LocalLeader>vk <Plug>VimspectorUpFrame
\\n   nmap     <buffer><silent><unique>  <LocalLeader><Up> <Plug>VimspectorUpFrame
\\n   nmap     <buffer><silent><unique>  <LocalLeader><Down> <Plug>VimspectorDownFrame
\"})
