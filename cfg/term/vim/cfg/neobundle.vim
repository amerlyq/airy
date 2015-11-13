" Install neobundle if it doesn't exist
let $BUNDLES=expand('$CACHE/bundle')
let $NEOBUNDLE=expand('$BUNDLES/neobundle.vim')

if has ('vim_starting')
  if !filereadable(expand('$NEOBUNDLE/README.md'))
      echo 'NeoBundle not found. Installing...'
      exec printf('!git clone --depth=1 %s',
            \ 'https://github.com/Shougo/neobundle.vim') $NEOBUNDLE
  endif
  set runtimepath^=$NEOBUNDLE
endif

let g:neobundle#default_options = {}
let g:neobundle#types#git#default_protocol = 'git'  " OR https, ssh
let g:neobundle#types#git#clone_depth = 1           "shallow copy
let g:neobundle#types#git#enable_submodule = 1

call neobundle#begin(expand('$BUNDLES'))
  if neobundle#load_cache()
    " Let NeoBundle manage NeoBundle
    NeoBundleFetch 'Shougo/neobundle.vim'
    call SourcePlugins()
    NeoBundleSaveCache
  endif

  "" Load develop version.
  " let s:vimrc_local = findfile('vimrc_local.vim', '.;')
  " if s:vimrc_local !=# ''
  "   call neobundle#local(fnamemodify(s:vimrc_local, ':h'),
  "         \ {}, ['vim*', 'unite-*', 'neco-*', '*.vim', '*.nvim'])
  " endif

  " call s:source_rc('plugins.rc.vim')
call neobundle#end()

filetype plugin indent on  " Required!

if !has('vim_starting')
  " Checks and installs all not installed bundles -- only on :so $MYVIMRC
  " WARNING :so don't work gracely with <unique> mappings...at all.
  NeoBundleCheck
  " Call on_source hook when reloading .vimrc.
  call neobundle#call_hook('on_source')
endif
