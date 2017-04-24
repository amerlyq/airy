" vim: ft=vim

"" Dir for all cached files
if exists('$XDG_DATA_HOME')
  let $VCACHE = $XDG_DATA_HOME.'/vim'
else
  let $VCACHE = expand('~/.cache/vim')
endif

"" Create cache dirs
let $CACHE = $VCACHE.'/cache'
for d in split('bundle bckp swap undo view')  " easytags.d
  if !isdirectory(expand('$CACHE/'.d))
    call mkdir(expand('$CACHE/'.d), 'p', 0700)
  endif
endfor
let $VPLUGS = $VCACHE.'/plugins'


" NOTE The '//' at directory end: use full path for filename with '%' separators
let $FALLBACK='~/.tmp,/var/tmp,/tmp'
set isfname-==  " Exclude = from isfilename.
" Swap
set directory=$CACHE/swap//,$FALLBACK
set swapfile
set updatetime=1000  " Save swap when inactive (ALSO interval for CursorHold)
" Backup
set backupdir=$CACHE/bckp,$FALLBACK
set backup writebackup backupcopy=auto
" View
set viewdir=$CACHE/view
" Undo
if v:version >= 703
  set undodir=$CACHE/undo//,$FALLBACK
  set undofile
endif
" Tags
set tags=./tags,tags,../tags,../../tags,*/tags,$VCACHE/tags
set tagbsearch      " Use a binary search (need sorted tags file!)
if v:version < 703 || (v:version == 703 && !has('patch336'))  " Vim's bug.
  set notagbsearch
endif

if !has("nvim")
  set viminfo+=n$CACHE/.viminfo
endif


" " Reload .vimrc automatically.
" autocmd MyAutoCmd BufWritePost .vimrc,vimrc,*.rc.vim,neobundle*.toml
"       \ NeoBundleClearCache | source $MYVIMRC | redraw
