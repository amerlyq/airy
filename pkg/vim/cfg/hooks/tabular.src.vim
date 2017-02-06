fun! s:Tabi(bang, ...)
  " Align on one-char, next word after one-char, or whole pattern
  " let patt = (a:0 > 0) ? a:1 :
  "             \ ((a:bang?'': '[') .nr2char(getchar()). (a:bang?'\s*\zs': ']'))
  let patt = '[' .nr2char(getchar()). ']'
  let aln = '/l'. v:count/10 .'r'. v:count%10
  exe 'Tabularize /' . patt . aln
endf

command! -bang -nargs=? Tabi call s:Tabi(<bang>0, <q-args>)

" Make line wrapping possible by resetting the 'cpo' option, first saving it
let s:save_cpo = &cpo
set cpo&vim

AddTabularPattern! first_comma /^[^,]*\zs,/r0c0l0

" AddTabularPipeline multiple_spaces / \{2,}/
"     \ map(a:lines, "substitute(v:val, ' \{2,}', '  ', 'g')")
"     \   | tabular#TabularizeStrings(a:lines, '  ', 'l0')

AddTabularPattern! asterisk /*/l1

AddTabularPipeline! remove_lead_spaces /^ /
              \ map(a:lines, "substitute(v:val, '^ *', '', '')")

" Restore the saved value of 'cpo'
let &cpo = s:save_cpo
unlet s:save_cpo
