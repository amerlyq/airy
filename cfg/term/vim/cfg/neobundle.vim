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


" ALT: py3file load_yaml.py
function! LoadFromYAML(path)
  if !exists(':PythonI') | finish | endif
PythonI << endofpython
import vim, yaml
with open(vim.eval("a:path")) as f:
  for src, opts in yaml.safe_load(f).items():
      vim.command("NeoBundle '{!s:s}', {}".format(src, opts))
endofpython
endfunc


let g:neobundle#default_options = {}
let g:neobundle#types#git#default_protocol = 'https'  " OR https, ssh
let g:neobundle#types#git#clone_depth = 1           " Shallow copy
let g:neobundle#types#git#enable_submodule = 1


call neobundle#begin(expand('$BUNDLES'))
  " if neobundle#load_cache()
    NeoBundleFetch 'Shougo/neobundle.vim'  " Manage self by itself
    call SourcePlugins()
    call LoadFromYAML(expand('$VIMHOME/cfg/plugins.yml'))
    " NeoBundleSaveCache
  " endif
  call SourcePluginsCfg()
call neobundle#end()  " Load all listed non-lazy plugins

" NeoBundleCheck
