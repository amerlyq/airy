" Install neobundle if it doesn't exist
let $BUNDLES=expand('$CACHE/bundle')
let $NEOBUNDLE=expand('$BUNDLES/neobundle.vim')
if !filereadable(expand('$NEOBUNDLE/README.md'))
    echom 'NeoBundle not found. Installing...'
    let neobundle='https://github.com/Shougo/neobundle.vim'
    silent exec '!git clone --depth=1 '.neobundle $NEOBUNDLE
endif

if has ('vim_starting')
  set runtimepath+=$NEOBUNDLE
endif

let g:neobundle#types#git#default_protocol = 'git'  " OR: https, ssh
let g:neobundle#types#git#clone_depth = 1   "shallow copy
let g:neobundle#types#git#enable_submodule = 1

call neobundle#begin(expand('$BUNDLES'))
  " if neobundle#load_cache()
  " Let NeoBundle manage NeoBundle
    NeoBundleFetch 'Shougo/neobundle.vim'
    source $VIMHOME/plugins.vim  " fnameescape(
    " NeoBundleSaveCache
  " endif
call neobundle#end()

filetype plugin indent on  " Required!
NeoBundleCheck  " Checks and installs all not installed bundles

if !has('vim_starting')
  " Call on_source hook when reloading .vimrc.
  call neobundle#call_hook('on_source')
endif
