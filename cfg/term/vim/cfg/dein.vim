""" NOTE: works only for Neovim / Vim7.4+

"" Add dein to runtime
for p in ['.dein', 'repos/github.com/Shougo/dein.vim']
  let p = $VCACHE.'/dein/'.p
  if filereadable(p.'/autoload/dein.vim')
    exe 'set runtimepath^=' . fnameescape(p)
    break
  endif
endfor
if &rtp !~# '\v/%(\.dein|dein\.vim)>'| finish |en


" let g:dein#install_log_filename = ''
if executable('git-up')  " EXPL:(gitconfig) alias git-up = '!git-up'
  let g:dein#types#git#pull_command = 'git-up'
endif
let g:dein#types#git#clone_depth = 1
let g:dein#install_max_processes = 8
" let g:dein#install_progress_type = 'title'
" let g:dein#install_message_type = 'none'
" let g:dein#enable_notification = 1


" BUG: recaches only on second time after changing rc files
"   -- OR first 'save_state' after chg rc saves wrong state
"   -- NOTE: unrelated to dein#begin 'watched files'
" ATTENTION: recache by 'call dein#clear_state()'
if !dein#load_state($VCACHE.'/dein')| finish |en
" echo '+ beg'

" NOTE: It overwrites your 'runtimepath' completely, you must
"   not call it after change 'runtimepath' dynamically.
fun! _hcat(nm)
  let cmd = IsWindows() ? 'type' : 'cat'
  let path = $VIMHOME . '/cfg/hooks/' . a:nm . '.vim'
  return system(cmd.' '.shellescape(path))
  " OR: -- when 'load_state' isn't used
  " return 'source '.fnameescape(path)
endf


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
" echo '+ end'
call dein#save_state()


" WARNING: Must be outside this file -- or ignored on 'load_state'
"   OR: completely drop ability to reload 'vimrc'
" if !has('vim_starting')
"   call dein#call_hook('source')
"   call dein#call_hook('post_source')

  " filetype plugin indent on
  " syntax enable
" endif
