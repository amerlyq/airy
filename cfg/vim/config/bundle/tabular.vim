" Provides extra :Tabularize commands

" Align on one-char
noremap <silent> <Leader>aa :<C-U>exec ('Tabularize /[' .nr2char(getchar()). ']/l0r0')<CR>
noremap <silent> <Leader>Aa :<C-U>exec ('Tabularize /[' .nr2char(getchar()). ']/l1r0')<CR>
noremap <silent> <Leader>aA :<C-U>exec ('Tabularize /[' .nr2char(getchar()). ']/l0r1')<CR>
noremap          <Leader>AA :Tabularize //l1r1<Left><Left><Left><Left><Left>
noremap          <Leader>AF :Tabularize /^[^,]*\zs,/l1r0

if !exists(':AddTabularPattern')
  finish " Give up here; the Tabular plugin musn't have been loaded
endif

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

