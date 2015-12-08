" Install neobundle if it doesn't exist
let $BUNDLES=expand('$CACHE/bundle')
let $NEOBUNDLE=expand('$BUNDLES/neobundle.vim')
let $BUNDLECFGS=expand('$VIMHOME/cfg/plugins-cfg')

if has('vim_starting')
  if !filereadable(expand('$NEOBUNDLE/README.md'))
    echo 'NeoBundle not found. Installing...'
    exec printf('!git clone --depth=1 %s',
          \ 'https://github.com/Shougo/neobundle.vim') $NEOBUNDLE
  endif
  set runtimepath^=$NEOBUNDLE
endif

let g:neobundle#default_options = {}
let g:neobundle#install_max_processes = 8
let g:neobundle#types#git#default_protocol = 'https'  " OR https, git, ssh
let g:neobundle#types#git#clone_depth = 1             " Shallow copy
let g:neobundle#types#git#enable_submodule = 1


call neobundle#begin(expand('$BUNDLES'))
" if neobundle#load_cache()

NeoBundleFetch 'Shougo/neobundle.vim'  " Manage self by itself

" Must not contain '\n' in path. Compat globpath <v7.4.279
let s:ymls = split(globpath(expand($VIMHOME.'/cfg/'), 'plugins/*.yml'), '\n')
let s:opts = {'lazy': 1}
fun! LoadFromYAMLs(py, paths, default)
  exe a:py expand($VIMHOME.'/cfg/yaml.py')
endf
 " If unsuccessful with auto-detected python, try to use python2
if LoadFromYAMLs('PythonF', s:ymls, s:opts) == -1
  call LoadFromYAMLs('pyfile', s:ymls, {'lazy': 1})
endif

" NeoBundleSaveCache
" endif
call _cfg('plugins-cfg/*.vim')
call neobundle#end()  " Load all listed non-lazy plugins

" Check new plugins if cache was cleared and plugins list reloaded:
if exists('*LoadFromYAMLs') | NeoBundleCheck | endif
