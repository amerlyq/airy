""" NOTE: works only for Neovim / Vim7.4+

"" TEMP:(convert *.yml)
" g/^\s\+description:\s\+/m-2|%s;;"" ;
" %s;mappings:;\\ 'on_map':;
" %s;commands:;\\ 'on_cmd':;
" %s;functions:;\\ 'on_func':;
" %s;depends:;\\ 'depends':;

" let g:dein#install_log_filename = ''
let g:dein#types#git#clone_depth = 1
if executable('git-up')
  let g:dein#types#git#pull_command = 'git-up'
endif
" let g:dein#install_progress_type = 'title'
" let g:dein#install_message_type = 'none'
" let g:dein#enable_notification = 1

let $BUNDLES=expand('$CACHE/bundle')
let $DEIN=expand('$BUNDLES/dein.vim')
let $DEINHOOKS=expand('$VIMHOME/cfg/plugins-cfg/on_hooks')
" ALT: using func '_hook()' to auto-distinguish 'add','source','post' parts
"   (+) incapsulated naming of 'hooks' path

if has('vim_starting')
  " Install dein if it doesn't exist
  if !filereadable(expand('$DEIN/README.md'))
    echo 'Dein not found. Installing...'
    exec printf('!git clone --depth=1 %s',
          \ 'https://github.com/Shougo/dein.vim') $DEIN
  endif
endif

set runtimepath^=$DEIN
" ATTENTION: recache by 'call dein#clear_state()'
if !dein#load_state($DEIN)| finish |en

" Monitors changes in listed rc files. Does 'filetype off'.
" ATTENTION: recache by 'call dein#recache_runtimepath()'
call dein#begin($BUNDLES, [expand('<sfile>')]
  \ + split(globpath(expand('<sfile>:h'), 'plugins/*.vim'), '\n'))
" NOTE: Must not contain '\n' in path. Compat globpath <v7.4.279

" THINK: how to remove duplicate 'dein.vim' from &rtp ?
" -- CHECK: conflicts with 'load_state'
call dein#add($DEIN)
call _cfg('plugins/*.vim')

" HACK'ed
call dein#add('amerlyq/nou.vim', {'on_ft': 'nou'})
call dein#add('amerlyq/forestanza.vim', {'on_ft': 'forestanza'})

" HACK: dev plugins override  ALSO: 'fork', 'vim*', 'unite-*'
for d in ['pj'] | let s:path = expand('~/aura/'.d)
  if isdirectory(s:path) | call dein#local(s:path,
      \ {'frozen': 1, 'merged': 0}, ['*.vim'])
endif | endfor

" call _cfg('plugins-cfg/*.vim')
call dein#end()  " recaches runtimepath
call dein#save_state()

" Check new plugins if cache was cleared and plugins list reloaded:
" if exists('*LoadFromYAMLs') | NeoBundleCheck | endif
if !has('vim_starting') && dein#check_install()
  " Installation check.
  call dein#install()
endif
