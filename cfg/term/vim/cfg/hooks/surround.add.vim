" BUG: in vimscript replace don't work for angle: <word> -> [<word>]
for op in ['append', 'delete', 'replace']
  call Map_nxo('[Quote]'.op[0], '<Plug>(operator-surround-'.op.')', 'nx')
endfor

let s:op = '<Plug>(operator-surround-append)'

"" Spaces as special quotes
call Map_nxo('[Quote]<Space>', s:op.'iw ', 'n')
call Map_nxo('[Quote]<Space>', s:op.' ', 'x')

"" Add quotes on qq
call Map_nxo('[Quote]q', s:op.'iW"', 'n')
call Map_nxo('[Quote]q', s:op.'"', 'x')

"" Add brackets by v<motion>q[<aliases>]
call Map_blocks('[Quote]', s:op, 'x', 'map')
