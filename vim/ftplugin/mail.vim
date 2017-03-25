setl commentstring=>\ %s
setl formatoptions+=w
setl textwidth=68
setl spell

let b:strip_spaces = 0
let b:strip_spaces_skip = g:strip_spaces_skip . '|%(^-- $)'


fun! s:reflow() range
  exe a:firstline
  exe 'norm! gq'. a:lastline .'G'
endf

fun! s:fixup()
  let l:pos = (exists('*getcurpos') ? getcurpos() : getpos('.'))
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

  call setpos('.', l:pos)
endf
call s:fixup()


""" BAD! don't use autocmd in ftplugin -- they never triggered
"  ! ftplugin sourced > Filetype event > BufRead completed

" if expand('%:t:e') == 'eml'
"   augroup MyMailEdits
"     au! * <buffer>
"     au! Filetype <buffer> [...]
"   augroup END
" endif
