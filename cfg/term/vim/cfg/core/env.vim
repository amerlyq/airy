" vim: ft=vim

set isfname-==  " Exclude = from isfilename.

"" Dir for all cached files
if isdirectory($XDG_CONFIG_HOME.'/vim')
  let $CACHE=expand('$XDG_CONFIG_HOME/vim')
else
  let $CACHE=expand('~/.cache/vim')
endif
set runtimepath^=$CACHE  " used for ./spell and 'before'

"" Create cache dirs
for d in split('bundle bckp spell swap undo view')  " easytags.d
  if !isdirectory(expand('$CACHE/' . d))
    call mkdir(expand('$CACHE/' . d), 'p', 0700)
  endif
endfor

" NOTE The '//' at directory end: use full path for filename with '%' separators
let $FALLBACK='~/.cache/tmp,~/.tmp,/var/tmp,/tmp'
" Swap
set directory=$CACHE/swap//,$FALLBACK
set swapfile
set updatetime=1000  " Save swap when inactive (ALSO interval for CursorHold)
" Backup
set backupdir=$CACHE/bckp,$FALLBACK
set backup writebackup backupcopy=auto
" View
set viewdir=$CACHE/view

if v:version >= 703
  set undodir=$CACHE/undo//,$FALLBACK
  set undofile
endif
if v:version < 703 || (v:version == 7.3 && !has('patch336'))  " Vim's bug.
  set notagbsearch
endif

if !has("nvim")
  set viminfo+=n$CACHE/.viminfo
endif


" " Reload .vimrc automatically.
" autocmd MyAutoCmd BufWritePost .vimrc,vimrc,*.rc.vim,neobundle*.toml
"       \ NeoBundleClearCache | source $MYVIMRC | redraw
