""" Python {{{1

call dein#add('hynek/vim-python-pep8-indent', {
  \ 'on_ft': 'python'})



" BUG: update error
" on_cmd: Pyimport
call dein#add('davidhalter/jedi-vim', {
  \ 'on_ft': 'python',
  \ 'hook_source': _hcat('jedi-vim.src')})



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
call dein#add('jupyter-vim/jupyter-vim', {
  \ 'on_ft': 'python',
  \ 'on_cmd': 'JupyterConnect',
  \ 'hook_source': "
\\n    let g:jupyter_mapkeys = 0
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>R :JupyterRunFile<CR>
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>I :PythonImportThisFile<CR>
\\n
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>X :JupyterSendCell<CR>
\\n    nnoremap <buffer><silent><unique>  <LocalLeader>E :JupyterSendRange<CR>
\\n    nmap     <buffer><silent><unique>  <LocalLeader>e <Plug>JupyterRunTextObj
\\n    vmap     <buffer><silent><unique>  <LocalLeader>e <Plug>JupyterRunVisual
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
