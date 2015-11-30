" USAGE:DEV:
"   set debug=msg fde=fold#level(v:lnum) fdm=expr | call fold#debug()
" CHG:./ftplugin/c.vim
"   setl foldexpr=fold#level(v:lnum)
"   setl foldmethod=expr

let s:cpo_save=&cpo
set cpo&vim

"""""""""""""""""""""""""" VARS """"""""""""""""""""""""""
" DEV: if you edited lines, then after edit:
"   - find upper/lower bounds with fold_level==0
"   - re-evaluate fold for all lines in this range
let b:n = 0
let b:n_inc = 200
let b:fold_levels = [0]  " Skip zero-line

fun! s:cache_resize(...) abort
  let blk0 = repeat([0], (a:0>0 ? max([0, b:n-a:1]) : b:n_inc))
  let b:fold_levels += blk0
endf

"""""""""""""""""""""""""" IMPL """"""""""""""""""""""""""
fun! s:blank(cl)
  return (a:cl =~# '^\s*$' ? '-1' : '?')
endf

fun! s:directive(cl, pl)
  if a:cl =~# '^#'
    return (a:pl =~ '^#' ? '-1' : '1')
  endif
  return '?'
endf

fun! s:declarations(cl, pl)
  if a:cl =~# '^#'
    return (a:pl =~ '^#' ? '-1' : '1')
  endif
  return '?'
endf

fun! s:block(cl, pl, nl)
  if a:cl =~ '\v(^\s*{\s*)'
    return '0'
  else
    return '1'
  endif
  return '?'
endf

"""""""""""""""""""""""""" CORE """"""""""""""""""""""""""
fun! fold#level(lnum)
  let cl = getline(a:lnum)
  let pl = prevnonblank(a:lnum-1)
  " let nl = nextnonblank(a:lnum+1)
  let n = s:blank(cl) | if n != '?' | return n | endif
  " " let n = s:block(cl, pl, nl) | if n != '?' | return n | endif
  let n = s:directive(cl, pl) | if n != '?' | return n | endif
  return 0
  " return foldlevel(a:lnum)
endf



"""""""""""""""""""""""""" API """""""""""""""""""""""""""
fun! fold#level(lnum)
  if b:n == 0 || lnum-b:n > b:n_inc
    call s:cache_resize(line('$'))
  elseif b:n < lnum
    call s:cache_resize()
  endif
  return b:fold_levels[a:lnum]
endf

"""""""""""""""""""""""""" DEBUG """""""""""""""""""""""""
fun! s:debug_window()
  norm! gg
  setl scrollbind
  setl nowrap nobreakindent  " Need to sync numbering
  setl nosplitright
  2 vnew
  setl nonumber norelativenumber foldcolumn=0 nowrap nobreakindent
  setl winfixwidth winfixheight
  setl buftype=nofile bufhidden=wipe nobuflisted
  norm! gg
  setl scrollbind
endf

fun! fold#debug()
  " let lvls = map(range(1, line('$')), 'fold#level(v:val)')
  let lvls = map(range(1, line('$')), 'foldlevel(v:val)')
  call s:debug_window()
  call append(line('1'), lvls)
endf

"---------------------------------------------------------
let &cpo=s:cpo_save
