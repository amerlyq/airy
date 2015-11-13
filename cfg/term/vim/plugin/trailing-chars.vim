" SEE Remove trailing spaces before saving text files
"   http://vim.wikia.com/wiki/Remove_trailing_spaces

"{{{1 KEYS ====================
noremap <unique> <Leader>tl :<C-u>set list! list?<CR>
noremap <unique> <Leader>tL :<C-u>TrailingHighlight<CR>

noremap <unique> <leader>cE :<C-u>EmptyLinesCompress<CR>


"{{{1 CMDS ====================
command! -bar -nargs=0 -range=% EmptyLinesCompress
    \ call RetainPos(printf('%s,%s s/%s//',
    \   <line1>, <line2>, '\v.\n\zs([ \t\u3000])*\n\ze.|^\1*\n\1*\_$'))

command! -bar -nargs=0 -range=% EmptyLinesRemove
    \ call RetainPos(printf('%s,%s g/%s/d_',
    \   <line1>, <line2>, '^[ \t\u3000]*$'))

command! -bar -nargs=0 -range=% EmptyLinesStripEnd
    \ call RetainPos(printf('/%s/,%sd_',
    \   '\v^%(\_[\n \t\u3000]*\S)@!', <line2>))

command! -bar -nargs=0 -range=% TrailingStrip
    \ if g:trailing_strip | call RetainPos(printf('%s,%s g/%s/s///ge',
    \   <line1>, <line2>, '\v[ \t\u3000]+$|[ \u3000]+\ze\t$')) | endif

command! -bar -nargs=0 -range TrailingToggle
    \ call ToggleVariable('g:trailing_strip')

" DEV THINK make independent from solarized high-contrast
command! -bar -nargs=0 -range TrailingHighlight
    \ let g:solarized_visibility=("low"==g:solarized_visibility?"high": "low")
    \| colorscheme solarized


"{{{1 IMPL ====================
fun! RetainPos(cmd)
  " ATTENTION Can't save/restore preffered column! USE cursor() instead.
  " EXPL let [l,c] = [line("."), col(".")] | ... | call cursor(l, c)
  let pos = getpos(".")
  silent! exe a:cmd
  call setpos('.', pos)
endf

fun! ToggleVariable(name)
  let {a:name} = !{a:name}
  echo '  '.a:name.' = '.({a:name} ? 'on' : 'off')
endf

let g:trailing_strip = 1
augroup TrailingStrip
  au!
  au BufWritePre * EmptyLinesStripEnd | TrailingStrip
augroup END
