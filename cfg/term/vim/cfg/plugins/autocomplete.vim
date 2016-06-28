""" Autocomplete

"" Dependency of Shougo stuff {{{1
call dein#add('Shougo/context_filetype.vim', {'lazy': 0})



"" CHECK: Check syntax on file save for many languages {{{1
call dein#add('scrooloose/syntastic', {'lazy': 0,
  \ 'hook_add': "
\\n   noremap <unique> [Toggle]x :<C-u>SyntasticToggleMode<CR>
\\n   source $DEINHOOKS/syntastic.vim
\"})



" Alt: bb:abudden/taghighlight "(small and fast) from bitbucket {{{1
" NOTE: easytags can make CursorMove very slow
"   https://github.com/xolox/vim-easytags/issues/68#issuecomment-28480981
"NeoBundle xolox/vim-easytags, { \ 'depends': xolox/vim-misc }



""" Neo-based

" THINK what can be useful to add {{{1
" repository = Shougo/neoinclude.vim
" repository = Shougo/neco-vim
" repository = Shougo/neco-syntax



"" CHECK: lua-based autocompletion framework, for all beside ycm {{{1
" Need much less memory.
" vim_version: 7.3.885
call dein#add('Shougo/neocomplete.vim', {
  \ 'if': '!has("lua") || has("nvim")',
  \ 'on_event': 'InsertEnter',
  \ 'depends': 'context_filetype.vim',
  \ 'hook_add': 'noremap <unique> [Toggle]N :<C-u>NeoCompleteToggle<CR>',
  \ 'hook_source': "
\\n  let g:neocomplete#enable_at_startup = 1
\\n  source $DEINHOOKS/neocomplete.vim
\"})



"" Like neocomplete but for neovim {{{1
" ATTENTION: :UpdateRemotePlugins and restart. Then once execute :DeopleteEnable
call dein#add('Shougo/deoplete.nvim', {'if': "has('nvim')",
  \ 'on_i': 1,
  \ 'depends': 'context_filetype.vim',
  \ 'hook_source': "
\\n    let g:deoplete#enable_at_startup = 1
\\n    source $DEINHOOKS/deoplete.vim
\"})

" call dein#add('zchee/deoplete-clang', {'on_ft': ['c', 'cpp']})
call dein#add('zchee/deoplete-jedi', {'on_ft': 'python'})
" call dein#add('zchee/deoplete-go', {'on_i': 1, 'on_ft': 'go'})



"" (DISABLED) Insert block pairs automatically, compatible with deoplete {{{1
" call dein#add('Shougo/neopairs.vim', {'on_i': 1
" hook_source: let g:neopairs#enable = 1
" hook_post_source: let g:neopairs#pairs = g:neopairs#_pairs})



"" Print documents (like function's arguments) in echo area {{{1
" CHECK: WTF? don't work...
" let g:echodoc_enable_at_startup = 1
call dein#add('Shougo/echodoc.vim', {
  \ 'on_event': 'CompleteDone',
  \ 'hook_source': 'call echodoc#enable()'})



" CHECK {{{1
" ALT 'SirVer/ultisnips'
" vim_version: 7.3.885  # NEED: event TextChanged,TextChangedI
" unite_sources: neosnippet{,/user,/runtime}
call dein#add('Shougo/neosnippet.vim', {
  \ 'on_event': 'InsertCharPre',
  \ 'on_ft': 'snippet',
  \ 'depends': ['neosnippet-snippets', 'context_filetype.vim'],
  \ 'hook_source': 'source $DEINHOOKS/neosnippet.vim'})

call dein#add('honza/vim-snippets', {'on_source': 'neosnippet.vim'})



""" Others

" (DISABLED: Shougo) Async clang code completion. {{{1
" Integration with neocomplete: for stdlib++, boost, etc (works on Windows)
" http://www.reddit.com/r/vim/comments/1x4mvg/vimmarching_with_neocomplete_doesnt_complete_c/
" call dein#add('osyo-manga/vim-marching', {
"   \ 'on_ft': ['c', 'cpp'],
"   \ 'depends': 'vimproc.vim',
"   \ 'hook_source': 'source $DEINHOOKS/vim-marching.vim'})



" CHECK: Lazy loading like this {{{1
"   autocmd FileType c,cpp NeoBundleSource clang_complete
" Rip-Rip/clang_complete:
"   filetypes: [c, cpp]
"   insert: 1
"  let g:clang_complete_auto = 0
"  let g:clang_auto_select = 0
"  let g:clang_default_keymappings = 0
"  "let g:clang_use_library = 1



"" YCM -- Autocompletion for Python and C-like languages {{{1
" Need Python2 exclusively
" Valloric/YouCompleteMe:
"     augroup: youcompletemeStart
"     \ 'on_cmd': [YcmDebugInfo]
"     filetypes: [c, cpp, python]
"     build:
"       linux: ./install.sh --clang-completer
"       # unix: ./install.sh --clang-completer --system-libclang
"     disabled: !has(python)
"     vim_version: 7.3.584

" TODO FIX: resolve completion conflicts -- seems like isn't disabled?
" autocmd FileType c,cpp if exists(:YcmCompleter) | NeoCompleteDisable | endif
" neocomplete: autoload: { filetypes: [ vim, sh, shell, votl ], }

" {{{Manual build instruction for YCM : if [ ! -e ./third_party/ycmd/ycm_core.so ]
"   1. git submodule update --init --recursive
"   2. cd third_party/ycmd && mkdir -p build && cd build && cmake .. ../cpp
"   5a. (optional) ccmake . # configure
"   6. make
" For win: https://github.com/Valloric/YouCompleteMe/wiki/Windows-Installation-Guide
" }}}
