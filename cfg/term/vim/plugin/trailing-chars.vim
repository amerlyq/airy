if &cp||exists('g:loaded_trailing')|finish|else|let g:loaded_trailing=1|endif
" SEE Remove trailing spaces before saving text files
"   http://vim.wikia.com/wiki/Remove_trailing_spaces

"{{{1 MAPS ====================
noremap <unique> [Toggle]l :<C-u>set list! list?<CR>
noremap <unique> [Toggle]L :<C-u>TrailingHighlight<CR>

noremap <unique> [Replace]E :<C-u>EmptyLinesCompress<CR>


"{{{1 CMDS ====================
command! -bar -nargs=0 -range=% EmptyLinesCompress
    \ call UnobtrusiveSubF('%s,%s s/%s//', <line1>, <line2>,
    \   '\v.\n\zs([ \t\u3000])*\n\ze.|^\1*\n\1*\_$')

command! -bar -nargs=0 -range=% EmptyLinesRemove
    \ call UnobtrusiveSubF('%s,%s g/%s/d_', <line1>, <line2>,
    \   '^[ \t\u3000]*$')

command! -bar -nargs=0 -range=% EmptyLinesStripEnd
    \ call UnobtrusiveSubF('/%s/,%sd_', '\v^%(\_[\n \t\u3000]*\S)@!',
    \ <line2>)

command! -bar -nargs=0 -range=% TrailingStrip
    \ call UnobtrusiveSubF('%s,%s g/%s/s///ge',
    \   <line1>, <line2>, '\v[ \t\u3000]+$|[ \u3000]+\ze\t$')

command! -bar -nargs=0 -range TrailingToggle
    \ call ToggleVariable('g:trailing_strip')

" DEV THINK make independent from solarized high-contrast
command! -bar -nargs=0 -range TrailingHighlight
    \ let g:solarized_visibility=("low"==g:solarized_visibility?"high": "low")
    \| colorscheme solarized


"{{{1 IMPL ====================
fun! UnobtrusiveSubF(...)
  let l:pos = (exists('getcurpos') ? getcurpos() : getpos('.'))
  silent! exe call(function("printf"), a:000)
  call histdel("search", -1)
  let @/ = histget("search", -1)
  call setpos('.', l:pos)
endf

fun! ToggleVariable(name)
  let {a:name} = !{a:name}
  echo '  '.a:name.' = '.({a:name} ? 'on' : 'off')
endf

let g:trailing_strip = 1
augroup TrailingStrip
  au!
  au BufWritePre * if g:trailing_strip|EmptyLinesStripEnd|TrailingStrip|en
augroup END
