" Install neobundle if it doesn't exist
let $BUNDLES=expand('$CACHE/bundle')
let $NEOBUNDLE=expand('$BUNDLES/neobundle.vim')


if has('vim_starting')
  if !filereadable(expand('$NEOBUNDLE/README.md'))
    echo 'NeoBundle not found. Installing...'
    exec printf('!git clone --depth=1 %s',
          \ 'https://github.com/Shougo/neobundle.vim') $NEOBUNDLE
  endif
  set runtimepath^=$NEOBUNDLE
endif


let g:neobundle#default_options = {}
let g:neobundle#types#git#default_protocol = 'git'  " OR https, ssh
let g:neobundle#types#git#clone_depth = 1           " Shallow copy
let g:neobundle#types#git#enable_submodule = 1


call neobundle#begin(expand('$BUNDLES'))
  if neobundle#load_cache()
    NeoBundleFetch 'Shougo/neobundle.vim'  " Manage self by itself
    call SourcePlugins()
    NeoBundleSaveCache
  endif
  call SourcePluginsCfg()
call neobundle#end()  " Load all listed non-lazy plugins
