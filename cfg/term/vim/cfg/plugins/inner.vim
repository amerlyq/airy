""" Inner/support/system

"" Main package manager {{{1
call dein#add('Shougo/dein.vim')



"" CHECK Async exec plugin for Vim. Dependency for Shougo plugins {{{1
" FIXME: must be cloned with dein.vim on first install!
" EXPL:(lazy: 0) NeoBundle uses it to update plugins
call dein#add('Shougo/vimproc.vim', {'lazy': 0, 'build': 'make'})



"" CHECK Make long-running tasks async {{{1
call dein#add('tpope/vim-dispatch', {'on_cmd': 'Make'})



"" (DISABLED) CHECK Powerful shell implemented by Vim script {{{1
" ALSO: [VimShellExecute, VimShellInteractive, VimShellTerminal, VimShellPop]
" call dein#add('Shougo/vimshell.vim', {
"   \ 'on_map': {'n', '<Plug>'},
"   \ 'on_cmd': 'VimShell'})
" hook_add = 'nmap [Space]s  <Plug>(vimshell_switch)'
" hook_source = 'source ~/.vim/rc/plugins/vimshell.rc.vim'



"" CHECK In unix terminal use snip-ranger-filechooser.vim {{{1
" ALSO: [VimFiler, VimFilerExplorer, Edit, Read, Source, Write]
" ALT: 'ctrlpvim/ctrlp.vim'
call dein#add('Shougo/vimfiler.vim', {
  \ 'if': IsWindows(),
  \ 'on_map': {'n': '<Plug>'},
  \ 'on_if': 'isdirectory(bufname("%"))',
  \ 'depends': 'unite.vim'})
" hook_add = 'nnoremap <silent>   [Space]v   :<C-u>VimFiler -invisible<CR>'
" hook_source = 'source ~/.vim/rc/plugins/vimfiler.rc.vim'
