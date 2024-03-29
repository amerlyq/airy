""" Inner/support/system

"" Main package manager {{{1
" TEMP:REM: revision fixed before hooks were broken: 'rev': 'e8be5b2'
call dein#add('Shougo/dein.vim', {'lazy': 0})



"" CHECK Async exec plugin for Vim. Dependency for Shougo plugins {{{1
" FIXME: must be cloned with dein.vim on first install!
" EXPL:(lazy: 0) NeoBundle uses it to update plugins
call dein#add('Shougo/vimproc.vim', {'lazy': 0, 'build': 'make -B'})



"" CHECK Make long-running tasks async {{{1
call dein#add('tpope/vim-dispatch', {
  \ 'on_cmd': ['Make', 'Dispatch', 'FocusDispatch', 'Start'],
  \ 'hook_post_source': "FocusDispatch abyss -r"})



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
" WARN: 'on_if' can break vim-signify
call dein#add('Shougo/vimfiler.vim', {
  \ 'if': IsWindows(),
  \ 'on_map': {'n': '<Plug>'},
  \ 'on_if': 'isdirectory(bufname("%"))',
  \ 'depends': 'unite.vim'})
" hook_add = 'nnoremap <silent>   [Space]v   :<C-u>VimFiler -invisible<CR>'
" hook_source = 'source ~/.vim/rc/plugins/vimfiler.rc.vim'


" if exists('*IsWindows') && IsWindows()
" TODO: override as with vim-over mappings (DFL vs plugin)
" noremap <unique>  <Leader>f :<C-U>VimFiler<CR>
" call dein#add('amerlyq/ranger.vim', {'lazy': 0, 'if': executable('ranger')})


" autocmd! BufWritePost * Neomake
" let g:neomake_cpp_enable_makers = ['clang', 'clangtidy']
" let g:neomake_cpp_clang_args = ['-std=c++14']
