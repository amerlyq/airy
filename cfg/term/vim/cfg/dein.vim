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
" ATTENTION: recache by 'call dein#clear_state()'
if !dein#load_state($DEIN)| finish |en

" Monitors changes in listed rc files. Does 'filetype off'.
" NOTE: Must not contain '\n' in path. Compat globpath <v7.4.279
" ATTENTION: recache by 'call dein#recache_runtimepath()'
call dein#begin($BUNDLES, [expand('<sfile>')]
  \ + split(globpath(expand('<sfile>:h'), 'plugins/*.yml'), '\n'))

" THINK: how to remove duplicate 'dein.vim' from &rtp ?
" -- CHECK: conflicts with 'load_state'
call dein#add($DEIN)
call _cfg('plugins/*.vim')

call dein#add('frankier/neovim-colors-solarized-truecolor-only')
call dein#add('tpope/vim-commentary')

" HACK'ed
call dein#add('amerlyq/nou.vim', {'on_ft': 'nou'})
call dein#add('amerlyq/forestanza.vim', {'on_ft': 'forestanza'})

" CHECK: dev plugins override  ALSO: 'fork', 'vim*', 'unite-*'
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
