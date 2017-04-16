setl commentstring=>%s
setl formatoptions+=w
setl textwidth=68
setl spell
setl foldmethod=syntax

let b:strip_spaces = 0
" NOTE: don't touch spaces in signature line '^--\s$'
let b:strip_spaces_skip = g:strip_spaces_skip . '|%(^-- $)'

fun! s:keeppos(ops)
  let l:pos = (exists('*getcurpos') ? getcurpos() : getpos('.'))
  exe a:ops
  call setpos('.', l:pos)
endf

fun! s:reflow() range
  exe a:firstline
  exe 'norm! gq'. a:lastline .'G'
endf

fun! s:fixup()
  """ Direct edits for mail body
  " Compress quotes at beg
  sil g /^>/ s/\v\>\zs\s+\ze\>//ge

  " Reflow quotes with depth=1
  " BAD: need visual select continuous ranges
  sil glob /\v^%(\>[^>[:blank:]])@!\ze.+\n%(\>[^>[:blank:]])/+
    \, /\v^%(\>[^>[:blank:]])\ze.+\n%(\>[^>[:blank:]])@!/
    \ call s:reflow()

  " Insert space between quotes and text
  sil g /^>/ s/\v^\>+\zs[^>[:blank:]]/ &/e
endf

""" Strip: BUG:DEV: my sign, others sign, all sign
" https://groups.google.com/forum/#!topic/comp.editors/JvQsUpiXqbI
" http://mutt-users.mutt.narkive.com/IbWZKIgz/remove-old-signature
fun! s:stripsign(all)
  if a:all
    sil! $ | /\v^\s*>+ -- *$/ | ?^[ >][ >]*$? | .,/^\s*$/-1d
  else  " Last only / last quoted only
    sil! $ | ?^-- $?,$ d _
  end
  "" Strip trailing spaces
  sil! /\v^%(\_[\n \t\xa0]*\S)@!/,$ d _
  "" Jump above citation OR:(simple): 1|/^$/|+
  sil! 1 | /^On\s.*\swrote:$/ | -
endf

com! -buffer -nargs=+ MailPos  call s:keeppos(<q-args>)
com! -buffer MailFixup   MailPos call s:fixup()
com! -buffer MailReflow  MailPos call s:reflow()
com! -buffer -bar MailStripSign  MailPos call s:stripsign(<bang>0)

nnoremap <silent> <buffer> <LocalLeader>f :MailFixup<CR>
nnoremap <silent> <buffer> <LocalLeader>r :MailReflow<CR>
nnoremap <silent> <buffer> <LocalLeader>s :MailStripSign<CR>
nnoremap <silent> <buffer> <LocalLeader>S :MailStripSign!<CR>

"" Always apply. Press 'undo' to restore in body.
MailFixup
" MailStripSign


""" BAD! don't use autocmd in ftplugin -- they never triggered
"  ! ftplugin sourced > Filetype event > BufRead completed

" if expand('%:t:e') == 'eml'
"   augroup MyMailEdits
"     au! * <buffer>
"     au! Filetype <buffer> [...]
"   augroup END
" endif
