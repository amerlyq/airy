""" NOTE: works only for Neovim / Vim7.4+
let s:dein = $VCACHE.'/dein'

"" Add dein to runtime
for p in ['.dein', 'repos/github.com/Shougo/dein.vim']
  if filereadable(s:dein.'/'.p.'/autoload/dein.vim')
    exe 'set runtimepath^=' . fnameescape(s:dein.'/'.p)
    break
  endif
endfor

if &rtp !~# '\v/%(\.dein|dein\.vim)>'| finish |en
" FIXME: eliminate duplicate in &rtp for .dein on load_state
let s:rtp = &rtp  " Back-up &rtp to restore on bad load_state


"" Options
" let g:dein#install_log_filename = ''
if executable('git-up')  " EXPL:(gitconfig) alias git-up = '!git-up'
  let g:dein#types#git#pull_command = 'git-up'
endif
let g:dein#types#git#clone_depth = 1
let g:dein#install_max_processes = 8
" let g:dein#install_progress_type = 'title'
" let g:dein#install_message_type = 'none'
" let g:dein#enable_notification = 1

" WARN: post hooks must be called manually; place before 'load_state'
autocmd MyAutoCmd VimEnter * nested call dein#call_hook('post_source')

" BUG: recaches only on second time after changing rc files
"   -- OR first 'save_state' after chg rc saves wrong state
"   -- NOTE: unrelated to dein#begin 'watched files'
"   -- ALSO: breaks saved &rtp in state_nvim.vim -- no '.dein' part
"   => EXPL:WARNING: consequences of '<unique>' exception when 'load_state'
" BUG: lazy on omap (ii, iz) -- bad first attempt -- messes up input

" NOTE: It overwrites your 'runtimepath' completely, you must
"   not call it after change 'runtimepath' dynamically.
" ATTENTION: recache by 'call dein#clear_state()'
if dein#load_state(s:dein)| let &rtp = s:rtp |else| finish |en


fun! _hcat(nm)
  let cmd = IsWindows() ? 'type' : 'cat'
  let path = $VIMHOME . '/cfg/hooks/' . a:nm . '.vim'
  return system(cmd.' '.shellescape(path))
  " OR: -- when 'load_state' isn't used
  " return 'source '.fnameescape(path)
endf


" Monitors changes in listed rc files. Does 'filetype off'.
" ATTENTION: recache by 'call dein#recache_runtimepath()'

call dein#begin(s:dein, [expand('<sfile>')]
  \ + split(globpath(expand('<sfile>:h'), 'plugins/*.vim'), '\n'))

call _cfg('plugins/*.vim')

" HACK: dev plugins override
" TODO: choose only currently actively developed ones
"   -- MAYBE check last change date is lesser then 10days?
call dein#local(expand('~/aura/vim'),
  \ {'frozen': 1, 'merged': 0}, ['*.vim', 'vim*', 'unite-*'])

call dein#end()  " Recaches runtimepath
call dein#save_state()


" WARNING: Must be outside this file -- or ignored on 'load_state'
"   OR: completely drop ability to reload 'vimrc'
" if !has('vim_starting')
"   call dein#call_hook('source')
"   call dein#call_hook('post_source')

  " filetype plugin indent on
  " syntax enable
" endif
