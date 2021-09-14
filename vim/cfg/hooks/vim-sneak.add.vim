" SEARCH sneak 's' -- 2-char (default) and clever-'f/t' -- 1-char enhanced
for c in split('sSfFtT', '\zs')
  call Map_nxo(c, '<Plug>Sneak_'. c)
endfor

"" DISABLED: unneeded -- repeating f/F or s/S "just works"
" JUMP next/prev -- explicit repeat (as opposed to implicit 'clever-s')
" call Map_nxo('<Del>', '<Plug>Sneak_;')
" call Map_nxo('<BS>', '<Plug>Sneak_,')
" BUG JUMP by label (as in browser) -- how to configure?
" call Map_nxo('<Leader><Del>', '<Plug>SneakLabel_s')
" call Map_nxo('<Leader><BS>', '<Plug>SneakLabel_S')
