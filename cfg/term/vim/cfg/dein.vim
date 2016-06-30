""" NOTE: works only for Neovim / Vim7.4+
let s:dein = $VCACHE.'/dein/repos/github.com/Shougo/dein.vim'
if &rtp!~#'/dein.vim' && !filereadable(s:dein.'/autoload/dein.vim')|finish|en

" CHECK: conflicts with 'load_state'
exe 'set runtimepath^=' . fnameescape(s:dein)
let $DEINHOOKS = $VIMHOME.'/cfg/hooks'


" let g:dein#install_log_filename = ''
if executable('git-up')  " EXPL:(gitconfig) alias git-up = '!git-up'
  let g:dein#types#git#pull_command = 'git-up'
endif
let g:dein#types#git#clone_depth = 1
let g:dein#install_max_processes = 8
" let g:dein#install_progress_type = 'title'
" let g:dein#install_message_type = 'none'
" let g:dein#enable_notification = 1


" NOTE: It overwrites your 'runtimepath' completely, you must
"   not call it after change 'runtimepath' dynamically.
" ATTENTION: recache by 'call dein#clear_state()'
" if !dein#load_state($VCACHE.'/dein')| finish |en
" BUG:FIXME: dein#tap in 'plugins/*' will never be called!

" Monitors changes in listed rc files. Does 'filetype off'.
" ATTENTION: recache by 'call dein#recache_runtimepath()'
call dein#begin($VCACHE.'/dein', [expand('<sfile>')]
  \ + split(globpath(expand('<sfile>:h'), 'plugins/*.vim'), '\n'))

call _cfg('plugins/*.vim')

" HACK: dev plugins override  ALSO: 'fork', 'vim*', 'unite-*'
for d in ['pj'] | let s:path = expand('~/aura/'.d)
  if isdirectory(s:path) | call dein#local(s:path,
      \ {'frozen': 1, 'merged': 0}, ['*.vim'])
endif | endfor

call dein#end()  " Recaches runtimepath
call dein#save_state()


if !has('vim_starting')
  call dein#call_hook('source')
  call dein#call_hook('post_source')

  " filetype plugin indent on
  " syntax enable
endif
