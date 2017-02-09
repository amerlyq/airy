""" Widgets

"" Toggle qf and loci lists {{{1
" DEV:TODO: merge with qf mappings
call dein#add('Valloric/ListToggle', {
  \ 'on_map': ['[Unite]q', '[Unite]l'],
  \ 'hook_source': "
\\n   let g:lt_location_list_toggle_map = '[Unite]l'
\\n   let g:lt_quickfix_list_toggle_map = '[Unite]q'
\"})



"" Tree of undo history with preview, timestamps and diff {{{1
" ALT: https://github.com/sjl/gundo.vim/
" Cmd: UndotreeFocus, UndotreeHide, UndotreeShow, UndotreeToggle
call dein#add('mbbill/undotree', {
  \ 'on_cmd': 'Undotree*',
  \ 'hook_add': "
\\n   nnoremap <silent><unique> [Unite]u  :UndotreeToggle<CR>
\", 'hook_source': "
\\n   let g:undotree_WindowLayout = 2
\\n   let g:undotree_SetFocusWhenToggle = 1
\\n   fun! g:Undotree_CustomMap()
\\n     nmap <buffer> <Space> <Plug>UndotreeEnter
\\n     nmap <buffer> d <Plug>UndotreeDiffToggle
\\n     nmap <buffer> f <Plug>UndotreeFocusTarget
\\n     nmap <buffer> J <Plug>UndotreeGoNextState
\\n     nmap <buffer> K <Plug>UndotreeGoPreviousState
\\n     nmap <buffer> t <Plug>UndotreeTimestampToggle
\\n   endf
\"})




"" Fast code-outline viewer dependent on ctags {{{1
" CHECK: if 'cmd' prefix works
" Highlight current tag in Tagbar on CursorHold
" Help <F1>, can change sort order on 's', show prototype on <Space>
" ALSO:SEE: TagbarOpenAutoClose, TagbarTogglePause, TagbarShowTag
call dein#add('majutsushi/tagbar', {
  \ 'if': executable('ctags'),
  \ 'on_cmd': 'Tagbar*',
  \ 'hook_add': 'nnoremap <silent><unique> [Unite]t  :TagbarToggle<CR>',
  \ 'hook_source': "
\\n   let g:tagbar_width = 30
\\n   \" show longest visible tag, =<N> for fixed
\\n   let g:tagbar_zoomwidth = 0
\\n   let g:tagbar_autoclose = 1
\\n   \" let g:tagbar_autofocus = 1
\\n   \" Sort manually on <s>
\\n   let g:tagbar_sort = 0
\\n   let g:tagbar_compact = 1
\\n   let g:tagbar_indent = 2
\\n   \" let g:tagbar_foldlevel = 2
\\n   let g:tagbar_autopreview = 1
\"})



"" Make diff for two regions in same/different buffers
call dein#add('AndrewRadev/linediff.vim', {
  \ 'on_cmd': ['Linediff', 'LinediffReset'],
  \ 'hook_add': "
\\n   nnoremap <unique> [Frame]l  :LinediffReset<CR>
\\n   vnoremap <unique> [Frame]l  :Linediff<CR>
\"})



"" Focus on line/selection/window in new buffer (supports recursive) {{1
"   * :NRL -- reopen last selected region
"   * :diffthis on two separate files/regions (THINK:ALT? to LineDiff)
" - :NRM -- useful for focused substitutions on multiple blocks
"   * :NRP[!] -- prepare[+clear_prev] selected lines for next :NRM
"   * you can completely delete blocks you don't want to change.
"   ALT: Edit short matches directly in qf by quickfix-reflector
" - :NUD -- when viewing unified diffs, show current chunk in split
"   * Repeat :NUD in unified diff window to update split-preview
" - Use another ft/filetype inside this block to edit code in mixed langs
"   ALT: Only for this -- https://github.com/AndrewRadev/inline_edit.vim
" ALSO: NN, [[ nx, <Leader>[nN], [Frame][nN] ]]
call dein#add('chrisbra/NrrwRgn', {
  \ 'on_func': 'nrrwrgn#',
  \ 'on_map': [['nx', '<Plug>Nrrwrgn']],
  \ 'on_cmd': ['NR', 'NW', 'NRV', 'NUD', 'NRP', 'NRM', 'NRL'],
  \ 'hook_source': _hcat('nrrwrgn.src'),
  \ 'hook_add': _hcat('nrrwrgn.add')})
