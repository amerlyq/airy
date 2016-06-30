for op in ['append', 'delete', 'replace']
  call Map_nxo('[Quote]'.op[0], '<Plug>(operator-surround-'.op.')', 'nx')
endfor

let s:op = '<Plug>(operator-surround-append)'

"" Add brackets on qq
call Map_nxo('[Quote]q', s:op.'iW"', 'n')
call Map_nxo('[Quote]q', s:op.'"', 'x')

"" Add brackets by v<motion>q[<aliases>]
call Map_blocks('[Quote]', s:op, 'x', 'map')
