if did_filetype()| finish |en
let s:cpo_save = &cpo
set cpo&vim

let s:L = getline(1,min([6,line('$')]))
fun! s:has(p, ...)
  let L = (a:0<1 ? s:L : (a:0<2 ? s:L[:a:1] : s:L[a:1:a:2]))
  return (0 <= match(L, a:p))
endf

if s:has('diff --git ', 2)
  set ft=diff
elseif s:has('\v^\u\l{2} \d{2} \d{2}:\d{2}:\d{2} \S', 1)
  set ft=messages
elseif s:has('^Disassembly of section')
  set ft=gas
endif

unlet s:L
delf s:has
let &cpo = s:cpo_save
