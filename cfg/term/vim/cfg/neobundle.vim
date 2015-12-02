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

" SEE ref for yaml:
"   http://www.yaml.org/refcard.html
"   http://learnxinyminutes.com/docs/yaml/
function! LoadFromYAMLs(cfgpaths, default)  " ALT: py3file load_yaml.py
  if !exists(':PythonI') | finish | endif   " SEE: core/detect.vim::PythonI
PythonI << endofpython
import vim, yaml, json  # Use json to correct '\' escaping when print(dict)
fmt = 'NeoBundle "{!s:s}", {!s}'
cfgs, defs = map(vim.eval, ("a:cfgpaths", "a:default"))
for c in (cfgs if isinstance(cfgs, list) else (cfgs,)):
  with open(c) as f:
    for doc in [doc for doc in yaml.safe_load_all(f) if doc is not None]:
      for src, opts in doc.items():
        if 'disabled' in opts:
          opts['disabled'] = vim.eval(opts['disabled'])
        # Remove to fasten loading
        [opts.pop(k, None) for k in ["description", "contract"]]
        vim.command(fmt.format(src, json.dumps(dict(defs, **opts))))
endofpython
endfunc

NeoBundleFetch 'Shougo/neobundle.vim'  " Manage self by itself
call LoadFromYAMLs(globpath(expand($VIMHOME.'/cfg/'),
      \ 'plugins/*.yml', 0, 1), {'lazy': 1})

" NeoBundleSaveCache
" endif
call _cfg('plugins-cfg/*.vim')
call neobundle#end()  " Load all listed non-lazy plugins

" Check new plugins if cache was cleared and plugins list reloaded:
if exists('*LoadFromYAMLs') | NeoBundleCheck | endif
