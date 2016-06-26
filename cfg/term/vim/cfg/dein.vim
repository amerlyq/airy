" let g:dein#install_progress_type = 'title'
" let g:dein#install_message_type = 'none'
" let g:dein#enable_notification = 1

let $BUNDLES=expand('$CACHE/bundle')
let $BUNDLECFGS=expand('$VIMHOME/cfg/plugins-cfg')
let $DEIN=expand('$BUNDLES/dein.vim')


if has('vim_starting')
  " Install dein if it doesn't exist
  if !filereadable(expand('$DEIN/README.md'))
    echo 'Dein not found. Installing...'
    exec printf('!git clone --depth=1 %s',
          \ 'https://github.com/Shougo/dein.vim') $DEIN
  endif
endif

set runtimepath^=$DEIN
" if !dein#load_state($DEIN)| finish |en
call dein#begin($BUNDLES)  " Does 'filetype off'
" call dein#begin(s:path, [expand('<sfile>')]
"      \ + split(glob('~/.vim/rc/*.toml'), '\n'))

 " Must not contain '\n' in path. Compat globpath <v7.4.279
" let s:ymls = split(globpath(expand($VIMHOME.'/cfg/'), 'plugins/*.yml'), '\n')
" let s:opts = {'lazy': 1}
" fun! LoadFromYAMLs(py, paths, default)
"   exe a:py expand($VIMHOME.'/cfg/yaml.py')
" endf
 " If unsuccessful with auto-detected python, try to use python2
" if LoadFromYAMLs('PythonF', s:ymls, s:opts) == -1
"   call LoadFromYAMLs('pyfile', s:ymls, s:opts)
" endif

call dein#add($DEIN)
call dein#add('frankier/neovim-colors-solarized-truecolor-only')
call dein#add('tpope/vim-commentary')  ", {'on_ft': 'nou'}
call dein#add('amerlyq/nou.vim')  ", {'on_ft': 'nou'}

" call dein#load_dict({
"   \ $DEIN : {},
"   \ 'frankier/neovim-colors-solarized-truecolor-only' : {},
"   \ 'tpope/vim-commentary' : {},
"   \ 'amerlyq/nou.vim' : {},
" \})

" NeoBundleSaveCache
" endif
" call _cfg('plugins-cfg/*.vim')
call dein#end()  " recaches runtimepath
" call dein#save_state()

" Check new plugins if cache was cleared and plugins list reloaded:
" if exists('*LoadFromYAMLs') | NeoBundleCheck | endif


if !has('vim_starting') && dein#check_install()
  " Installation check.
  call dein#install()
endif
