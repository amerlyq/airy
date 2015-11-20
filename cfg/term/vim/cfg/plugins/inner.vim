" ALT: names: inner/support/system
":Make cover for long-running tasks asynchronous (as like by ssh)
NeoBundle 'tpope/vim-dispatch'

" Asynchronous execution plugin for Vim
" Must not be lazy for neobundle to use it to update plugins
NeoBundle 'Shougo/vimproc.vim', {
  \ 'lazy': 0,
    \ 'external_commands' : 'make',
    \ 'build' : {
    \     'windows' : 'tools\\update-dll-mingw',
    \     'cygwin' : 'make -f make_cygwin.mak',
    \     'mac' : 'make -f make_mac.mak',
    \     'linux' : 'make',
    \     'unix' : 'gmake',
    \ }}

" Powerful shell implemented by Vim script
NeoBundleLazy 'Shougo/vimshell.vim', {
    \ 'depends' : 'Shougo/vimproc.vim',
    \ 'external_commands' : 'make',
    \ 'autoload' : {
    \   'commands' : [{ 'name' : 'VimShell',
    \                   'complete' : 'customlist,vimshell#complete'},
    \                 'VimShellExecute', 'VimShellInteractive',
    \                 'VimShellTerminal', 'VimShellPop',
    \              ],
    \   'mappings' : ['<Plug>(vimshell_'],
    \ }}

" ======================================
if IsWindows()
" In unix terminal use snip-ranger-filechooser.vim
NeoBundleLazy 'Shougo/vimfiler.vim', {
    \ 'depends' : 'Shougo/unite.vim',
    \ 'disabled' : has('unix') && !has('gui_running'),
    \ 'autoload' : {
    \    'commands' : [{ 'name' : 'VimFiler',
    \                    'complete' : 'customlist,vimfiler#complete' },
    \                  'VimFilerExplorer',
    \                  'Edit', 'Read', 'Source', 'Write'],
    \    'mappings' : ['<Plug>(vimfiler_'],
    \    'explorer' : 1,
    \ }}
endif
