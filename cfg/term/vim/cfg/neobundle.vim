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
let g:neobundle#types#git#default_protocol = 'https'  " OR https, ssh
let g:neobundle#types#git#clone_depth = 1           " Shallow copy
let g:neobundle#types#git#enable_submodule = 1


call neobundle#begin(expand('$BUNDLES'))
" if neobundle#load_cache()
NeoBundleFetch 'Shougo/neobundle.vim'  " Manage self by itself

function! LoadFromYAMLs(cfgpaths, default)  " ALT: py3file load_yaml.py
  if !exists(':PythonI') | finish | endif   " SEE: core/detect.vim::PythonI
PythonI << endofpython
import vim, yaml
fmt = "NeoBundle '{!s:s}', {}"
cfgs, defs = map(vim.eval, ("a:cfgpaths", "a:default"))
for c in (cfgs if isinstance(cfgs, list) else (cfgs,)):
    with open(c) as f:
        for doc in yaml.safe_load_all(f):
            for src, opts in doc.items():
                vim.command(fmt.format(src, dict(defs, **opts)))
endofpython
endfunc

call SourcePlugins()
call LoadFromYAMLs(globpath(expand($VIMHOME.'/cfg/'),
      \ 'plugins/*.yml', 0, 1), {'lazy': 1})
" NeoBundleSaveCache
" endif
call SourcePluginsCfg()
call neobundle#end()  " Load all listed non-lazy plugins
" NeoBundleCheck
