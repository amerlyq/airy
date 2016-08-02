if did_filetype()| finish |en
let s:cpo_save = &cpo
set cpo&vim

let s:line1 = getline(1)
let s:line2 = getline(2)
let s:line3 = getline(3)

let s:patt = '\v^\u\l{2} \d{2} \d{2}:\d{2}:\d{2} \S'
if s:line1 =~ s:patt || s:line2 =~ s:patt
  set ft=messages
endif

unlet s:patt s:line1 s:line2 s:line3
let &cpo = s:cpo_save
