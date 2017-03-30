let s:op = '<Plug>(operator-surround-append)'
let s:sd = '<Plug>(operator-surround-delete)'
let s:rc = '<Plug>(operator-surround-replace)'

" BUG: in vimscript replace don't work for angle: <word> -> [<word>]
call Map_nxo('[Quote]a', s:op, 'nx')
call Map_nxo('[Quote]d', s:sd, 'nx')
call Map_nxo('[Quote]r', s:rc, 'nx')

call Map_nxo('[Quote]dd', s:sd.'aW', 'nx')
call Map_nxo('[Quote]dD', s:sd.'ab', 'nx')

"" Word-based quoting (reversed by frecency)
call Map_nxo('[Quote]w', s:op.'iW', 'n')
call Map_nxo('[Quote]W', s:op.'iw', 'n')
" DEV: xmap 'qw..' -- add quotes to each word in selection
" call Map_nxo('[Quote]<Space>', s:op.' ', 'x')

"" Spaces as special quotes
call Map_nxo('[Quote]<Space>', s:op.'iw ', 'n')
call Map_nxo('[Quote]<Space>', s:op.' ', 'x')

"" Add quotes on qq
call Map_nxo('[Quote]q', s:op.'iW"', 'n')
call Map_nxo('[Quote]q', s:op.'"', 'x')

"" Add brackets by v<motion>q[<aliases>]
call Map_blocks('[Quote]', s:op, 'x', 'map')

"" Accents for *.nou
call Map_blocks('[Quote]', s:op.'iW', 'n', 'map', '**;__;~~')
call Map_blocks('[Quote]', s:op, 'x', 'map', '**;__;~~')
