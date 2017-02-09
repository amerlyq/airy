" SEARCH sneak 's' -- 2-char (default) and clever-'f/t' -- 1-char enhanced
for c in split('sSfFtT', '\zs')
  call Map_nxo(c, '<Plug>Sneak_'. c)
endfor

" JUMP next/prev -- explicit repeat (as opposed to implicit 'clever-s')
call Map_nxo('<CR>', '<Plug>SneakNext')
call Map_nxo('<BS>', '<Plug>SneakPrevious')
" BUG JUMP by label (as in browser) -- how to configure?
call Map_nxo('<Leader><CR>', '<Plug>(SneakStreak)')
call Map_nxo('<Leader><BS>', '<Plug>(SneakStreakBackward)')
