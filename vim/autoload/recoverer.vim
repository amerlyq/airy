" @license MIT, (c) amerlyq, 2015

" PLAN au
"   allow tableave (for ranger or opening additional files before decide on swap)
"   'diffend' on bufchange in that tab or deleting any of buf in that tab
"   'diffend' on buf write -- to continue editing opened buf with stagnated swap
"   DECIDE on quit: ask to remove or keep as is
"   THINK: how to restore origin buf instead of recovered w/o exiting
"     IDEA: close recovered == keep origin (discard changes), close origin == keep recovered


" BAD: we mustn't reset whole 'au'
"   * it may contain diff sets of au from diff files with swaps at once
"   => reset in each func only related to <afile> 'au's
fun! recoverer#reset_au()
  augroup recoverer_once
    au!
  augroup END
endf


" FIXME: multiple swap diffs at once -> individual 'sw' -> for buffer
"   TRY: :bufdo
"   TRY:
" BAD: switch to buffer => '%' becomes != <abuf>
"   exe a:buf.'buffer' !!! Problems
fun! s:getswapname()
  redir => _|sw|redir END
  let _ = substitute(_,'[\r\n]','','g')
  let _ = _[:-2].nr2char(char2nr(_[-1:])+1)
  return _
endfun


" TODO: after first prompt of 'remove' must delete all <buffer> autocmd to
"   prevent repeating of prompt
fun! recoverer#remove(buf, swap) abort
  if !filereadable(a:swap)| return |en
  unsilent if confirm('RM? '.a:swap,"&Y\n&n",1)==1
    if 0==delete(a:swap)| echo 'OK'
    else|throw "Err: can't delete swap: '".a:swap."'" |en
  endif
  if getbufvar(a:buf, '&swapfile') && empty(getbufvar(a:buf, '&buftype'))
    " Reset swapfile to use .swp extension
    "   sil setl noswapfile swapfile
    call setbufvar(a:buf, '&swapfile', 0)
    call setbufvar(a:buf, '&swapfile', 1)
  endif
endf


fun! s:exe(fmt, ...)
  exe call('printf', [a:fmt] + map(copy(a:000), "escape(v:val, \"'\")"))
endf

" THINK: recover, save, reread, DiffOrig
"   BET http://stackoverflow.com/questions/19526284/vim-clone-a-buffer-and-make-it-hidden
"   http://stackoverflow.com/questions/21385956/undo-recovery-from-swap-file-in-vim
"     new | put =getbufline('#',1,'$') | 1d_
"     let buffer_number = bufnr('My New Hidden Buffer', 1)
"   ? use :saveas
"   http://stackoverflow.com/questions/5824962/vim-command-for-edit-a-copy-of-this-file
fun! recoverer#on_enter(file, swap) abort
  " NOTE: reset to remove BufEnter recursion
  " ALT: call recoverer#reset_au()
  exe 'au! recoverer BufEnter '.fnameescape(a:file)
  echom a:file

  " BUG: due to 'nested' all autocmds will be called twice -- as in 'vim-gnupg'
  exe 'tabedit' a:file
  let bf = bufnr('')
  let orgnlines = getbufline(bf, 1, '$')
  try| recover |catch /^Vim\%((\a\+)\)\=:E305/|call s:warning('Swap file not found')|endtry
  let recvlines = getbufline(bf, 1, '$')
  " NOTE: prevent recursion on reloading file with swap
  let b:recoverer_swapchoice = 'e'
  edit!
  unlet b:recoverer_swapchoice
  diffthis


  enew | 0put = l:recvlines | $delete_
  setl bt=nofile noswapfile  " nobuflisted,  setg nowrite
  " CHG: use tab naming similar to '(swap)/path/to/file'
  file =Origin=
  diffthis
  %diffput
  %delete _ | exe 'read ++edit' a:file | 1 delete _
  " %delete _ | put = l:orgnlines | 1 delete _
  " ALT:BAD: '$delete_' kills whole fold
  " %delete _ | 0put = readfile(a:file) | $ delete _
  " %delete_ | 0put = l:orgnlines | $delete_
  " %delete_ | exe '0read ++edit' a:file | $delete_
  setl nomodifiable
  diffupdate
  %foldclose

  call s:exe("au recoverer BufDelete <buffer> windo diffoff | tabclose "
    \.tabpagenr()."| call recoverer#remove('%s','%s')"
    \, expand('<abuf>'), a:swap)
  call s:exe("au recoverer QuitPre <buffer> call recoverer#remove('%s','%s')"
    \, expand('<abuf>'), a:swap)

  exe 'vsplit' a:file
  %foldclose

  call s:exe("au recoverer BufDelete <buffer> windo diffoff | tabclose "
    \.tabpagenr()."| call recoverer#remove('%s','%s')"
    \, expand('<abuf>'), a:swap)
  call s:exe("au recoverer QuitPre <buffer> call recoverer#remove('%s','%s')"
    \, expand('<abuf>'), a:swap)

  """ BAD.5
  " enew
  " let bo = bufnr('')
  " %delete_ | put = getbufline(bf, 1, '$') | 1delete _
  " setl bt=nofile nowrite noswapfile  " nobuflisted
  " " CHG: use tab naming similar to '(swap)/path/to/file'
  " file =Origin=
  " diffthis
  " exe 'vsplit' a:file
  " recover
  " let recvlines = getbufline(bf, 1, '$')
  " %delete_ | put = getbufline(bo, 1, '$') | 1delete _
  " %delete_ | put = l:recvlines | 1delete _
  " %delete_ | put = getbufline(bo, 1, '$') | 1delete _
  " %delete_ | put = l:recvlines | 1delete _
  " diffthis
  " wincmd p

  " THINK:RFC: replace file content cloning by smth more direct and atomic
  " DiffOrig: vert new | set bt=nofile | r ++edit # | 0d_ | diffthis | wincmd p | diffthis

  " let cmd = '%delete_ | put = a:lst | 1delete _'
  " exe 'read ++edit' a:file | 1d_ | diffthis
  " ALT: exe '0read ++edit' a:file | diffthis
  " TODO: remove file content reading from edit history
  "   https://superuser.com/questions/214696/how-can-i-discard-my-undo-history-in-vim
  " setl nomodifiable nomodified

  """ ALT:HACK: exe 'vsplit' a:file | recover | diffthis
  " BAD.1(undo break not working): let &undolevels=&undolevels
  " BAD.2(recover discards changes): exe "norm! i\<C-g>u\<Esc>" OR :m-1
  " BAD.3(buffer with same name exists): tabnew | exe 'file' a:file
  "   =An unlisted buffer is created to hold the old |alternate-file| name.
  " BAD.4(no effect on undo history): :preserve
  " BAD.5(undo breaks but w/o changes:)
  "   %delete_ | put = getbufline(borigin, 1, '$') | 1delete _
  "   %delete_ | put = l:recoveredlines | 1delete _
  " DEV:TRY: re-read file content in-place
  " ALT:TRY: :saveas tempname() w/o swap -> open origin -> %diffput -> clone origin -> diff -> del origin
  "   http://stackoverflow.com/questions/6257260/use-vimdiff-to-replace-entire-file


  " let t = tabpagenr()
  " " CHG:BET: autocmd-buflocal
  " exe "au recoverer_once TabLeave ".t." call recoverer#diffend(".t.")"
  " exe "au recoverer_once QuitPre {=Origin=,".fnameescape(a:file)."} call recoverer#diffend(".t.")"
  " exe "au recoverer_once BufDelete {=Origin=,".fnameescape(a:file)."} call recoverer#diffend(".t.")"
endf


" fun! recoverer#diffend(t) abort
"   " NOTE: no need -- as autocmd must be destroyed when buff removed
"   " au! recoverer BufDelete,QuitPre <buffer>
"   windo diffoff
"   " call recoverer#reset_au()
"   " BET: delete by saved bufnr('')
"   " bdelete =Origin= " TODO: Check if exists
"   let b = expand('<abuf>')
"   exe 'bdelete' b
"   exe 'tabclose' a:t
"   call recoverer#remove(b)
"   " DEV: remove read-only attribute if choice was to delete swap
" endf


fun! s:warning(...)
  echohl WarningMsg
  exe 'echo'.(get(a:,2)?'m':'') string(get(a:,1))
  echohl None
endf


fun! s:read_bin_uint(file, off, len) abort
  let v = 'od -An -tu2 -j%d -N%d %s'
  let v = system(printf(v, a:off, a:len, shellescape(a:file)))
  let v = substitute(v, '\v^\_\s*(\d{-})\_\s*$', '\1', '')
  if v =~ '[^0-9]'| throw 'Wrong number: '.pid |en
  return v+0
endf


fun! recoverer#is_owner_running(swap) abort
  let pid = s:read_bin_uint(a:swap, 24, 2)
  let comm = '/proc/'.pid.'/comm'
  if !filereadable(comm)| return 0 |en
  let pname = get(readfile(comm, '', 1), 0, '')
  return (pname =~# '^n\?vim$' ? pid : 0)
endf


fun! recoverer#is_modified(swap) abort
  " REF: https://groups.google.com/forum/#!topic/vim_use/Y3E3xLWn-1w
  "   SEE: vim/memfile.c -> struct block0 -> 0x55 at pos 0x3ef
  return (s:read_bin_uint(a:swap, 1007, 1) == 0x55)
endf


" NOTE: v:swapcommand contains part of cmd which opened file
fun! recoverer#on_swap(...) abort
  " TEMP:RFC: choice must be reset anew after checking if swap exists or :w/:e
  "   ? WTF if reopen closed file in same session ? will b:var be preserved ?
  if !empty(get(b:, 'recoverer_swapchoice'))
    let v:swapchoice = b:recoverer_swapchoice
    return
  endif

  let f = fnamemodify(get(a:, 1, expand('<afile>')), ':p')
  let s = fnamemodify(get(a:, 2, v:swapname), ':p')
  let pid = recoverer#is_owner_running(s)
  call recoverer#reset_au()  " BAD:SEE explanation at top

  echom f

  if pid
    let v:swapchoice = 'o'
    " SEIZE: https://vi.stackexchange.com/questions/56/how-can-i-prevent-vim-from-leaving-too-many-files-like-swap-backup-undo
    "   let &swapfile = &modified
    " ATT: cannot 'nowrite' per buffer, only whole vim instance
    setl nomodifiable noswapfile

    " FIXED:HACK: echo'ed msg disappears after swapchoice
    exe 'au recoverer_once BufEnter '.fnameescape(f)
      \." call s:warning('File already opened in pid="
      \.(pid==getpid() ?'this': pid)."', 1)"

  elseif recoverer#is_modified(s)
    let v:swapchoice = 'e'
    " FIXME if getfsize(f) > 1024*1024| return |en
    " DEV: diff modified

    exe printf("au recoverer BufEnter %s nested"
      \." call recoverer#on_enter('%s', '%s')"
      \, fnameescape(f), escape(f, "'"), escape(s, "'"))

  else
    " NOTE: delete unmodified swapfiles w/o pid
    let v:swapchoice = 'd'
  endif
endf
