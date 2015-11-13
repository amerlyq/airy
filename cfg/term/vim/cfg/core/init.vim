" vim: ft=vim
" Set augroup.
augroup MyAutoCmd
  autocmd!
augroup END

"" DISABLED default plugins
" Disable GetLatestVimPlugin.vim
if !&verbose | let g:loaded_getscriptPlugin = 1 | endif
let g:loaded_2html_plugin = 1
let g:loaded_vimballPlugin = 1
""CASE Netrw {{{1 Allows one to view the contents of an http hyperlink via CTRL-W_CTRL-F
"" launch as $ agent tempfile url -- See: https://github.com/danchoi/elinks.vim
"let g:netrw_http_cmd = "elinks-for-vim"
" let g:netrw_home=$CACHE
let g:loaded_netrwPlugin = 1
""CASE Match {{{1 Temporary jumps to show matching parenthesis:
" let g:loaded_matchparen = 1    " Matching parentheses: hooks on Cursor*,Win*
" set showmatch matchtime=1 cpoptions-=m
let g:did_install_default_menus = 1  " Disable menu


"{{{1 Once/startup ============================
if has('vim_starting')
  " Augment Windows Platform
  if IsWindows()
    set shellslash  " Exchange path separator.
    set lines=32
    set columns=112
    let &runtimepath = join([
          \ expand('~/.vim'),
          \ expand('$VIM/runtime'),
          \ expand('~/.vim/after')], ',')
    " Fix the path of vimrc and gvimrc for Windows
    let $MYVIMRC=$VIMHOME . '/vimrc'
    let $MYGVIMRC=$VIMHOME . '/gvimrc'
    language message en_US.UTF-8
    cd d:\
  else
    language message C " Use English interface.
  endif
endif
