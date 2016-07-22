" vim: ft=vim

"" DISABLED default plugins
" Disable GetLatestVimPlugin.vim
if !&verbose | let g:loaded_getscriptPlugin = 1 | endif
let g:loaded_2html_plugin = 1
let g:loaded_vimball = 1
let g:loaded_vimballPlugin = 1

""CASE Netrw {{{1 Allows one to view the contents of an http hyperlink via CTRL-W_CTRL-F
"" launch as $ agent tempfile url -- See: https://github.com/danchoi/elinks.vim
"let g:netrw_http_cmd = "elinks-for-vim"
" let g:netrw_home=$CACHE
" let g:loaded_netrwPlugin = 1  " ATTENTION: scp:// isn't working w/o netrw
" let g:loaded_netrw             = 1
" let g:loaded_netrwSettings     = 1
" let g:loaded_netrwFileHandlers = 1

""CASE Match {{{1 Temporary jumps to show matching parenthesis:
" let g:loaded_matchparen = 1    " Matching parentheses: hooks on Cursor*,Win*
" set showmatch matchtime=1 cpoptions-=m

let g:did_install_default_menus = 1  " Disable menu

let g:loaded_gzip              = 1
let g:loaded_tar               = 1
let g:loaded_tarPlugin         = 1
let g:loaded_zip               = 1
let g:loaded_zipPlugin         = 1
let g:loaded_rrhelper          = 1
let g:loaded_getscript         = 1
let g:loaded_getscriptPlugin   = 1
let g:loaded_LogiPat           = 1
let g:loaded_logipat           = 1
let g:loaded_tutor_mode_plugin = 1
let g:loaded_spellfile_plugin  = 1  " don't source 'spell/<LANG>.vim'
let g:loaded_man               = 1
let g:loaded_matchit           = 1
