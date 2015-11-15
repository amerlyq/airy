"{{{1 Neo ============================
" Async clang code completion.
" Integration with neocomplete: for stdlib++, boost, etc (works on Windows)
" http://www.reddit.com/r/vim/comments/1x4mvg/vimmarching_with_neocomplete_doesnt_complete_c/
NeoBundle 'osyo-manga/vim-marching', { 'depends' : 'Shougo/vimproc.vim' }

" THINK what can be useful to add
" repository = 'Shougo/neoinclude.vim'
" repository = 'Shougo/neco-vim'
" repository = 'Shougo/neco-syntax'

NeoBundleLazy 'Shougo/neocomplete.vim', {
    \ 'autoload' : { 'insert': 1 },
    \ 'depends' : [ 'Shougo/context_filetype.vim' ],
    \ 'vim_version' : '7.3.885',
    \ 'disabled' : !has('lua') }

" DO: :UpdateRemotePlugins and restart. Then once execute :DeopleteEnable
let g:deoplete#enable_at_startup = 1
NeoBundle 'Shougo/deoplete.nvim', {
    \ 'autoload' : { 'insert': 1 },
    \ 'depends' : [ 'Shougo/context_filetype.vim' ],
    \ 'disabled' : !has('nvim') }

" ALT SirVer/ultisnips
NeoBundleLazy 'Shougo/neosnippet.vim', {
    \ 'autoload' : { 'filetypes': 'snippet', 'insert': 1 },
    \ 'depends' : [
    \   'Shougo/context_filetype.vim',
    \   'Shougo/neosnippet-snippets',
    \   'honza/vim-snippets' ],
    \ 'unite_sources': [
    \   'neosnippet', 'neosnippet/user', 'neosnippet/runtime'] }
    " \ 'disabled' : !has('lua'),
    " \ 'vim_version': '7.3.885'


"{{{1 Clang ============================
"Lazy loading like this
"NeoBundleLazy 'Rip-Rip/clang_complete'
"autocmd FileType c,cpp NeoBundleSource clang_complete


"{{{1 YCM ============================
" "" Autocompletion for Python and C-like languages. Need Python2 exclusively
" NeoBundleLazy 'Valloric/YouCompleteMe', {
"     \ 'augroup': 'youcompletemeStart',
"     \ 'autoload': {
"     \   'commands' : ['YcmDebugInfo'],
"     \   'filetypes' : [ 'c', 'cpp' ],
"     \ },
"     \ 'build': {
"     \   'linux': './install.sh --clang-completer',
"     \ },
"     \ 'disabled': !has('python'),
"     \ 'vim_version': '7.3.584',
"     \ }
"     " \   'unix': './install.sh --clang-completer --system-libclang'

" TODO FIX: resolve completion conflicts -- seems like isn't disabled?
" autocmd FileType c,cpp if exists(':YcmCompleter') | NeoCompleteDisable | endif
" neocomplete: 'autoload': { 'filetypes' : [ 'vim', 'sh', 'shell', 'votl' ], },

" {{{Build instruction for YCM : if [ ! -e './third_party/ycmd/ycm_core.so' ]
"   1. git submodule update --init --recursive
"   2. cd third_party/ycmd && mkdir -p build && cd build && cmake .. ../cpp
"   5a. (optional) ccmake . # configure
"   6. make
" For win: https://github.com/Valloric/YouCompleteMe/wiki/Windows-Installation-Guide
" }}}
