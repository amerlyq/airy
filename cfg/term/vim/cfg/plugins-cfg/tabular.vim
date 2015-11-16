" Provides extra :Tabularize commands
function! s:Tabi(bang, ...)
    " Align on one-char, next word after one-char, or whole pattern
    " let patt = (a:0 > 0) ? a:1 :
    "             \ ((a:bang?'': '[') .nr2char(getchar()). (a:bang?'\s*\zs': ']'))
    let patt = '[' .nr2char(getchar()). ']'
    let aln = '/l'. v:count/10 .'r'. v:count%10
    exec 'Tabularize /' . patt . aln
endfunction
command! -bang -nargs=? Tabi call s:Tabi(<bang>0, <q-args>)

noremap         <unique>  [Frame]A  :Tabularize /<C-R>//l1r1
noremap         <unique>  [Frame]gA :Tabularize /^[^:]*\zs:/l0c1r0
noremap <silent><unique>  [Frame]a  :<C-U>Tabi<CR>
noremap <silent><unique>  [Frame]ga :<C-U>Tabi!<CR>
noremap <silent><unique>  [Frame]g: :Tabularize /:\s*\zs\S/l1l0<CR>
noremap <silent><unique>  [Frame]g# :Tabularize /#\ze[^#]*$/l2l1<CR>
noremap <silent><unique>  [Frame]g<bar> :Tabularize /<bar>/l1l1<CR>

" Give up here; the Tabular plugin musn't have been loaded
if !exists(':AddTabularPattern') | finish | endif

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
