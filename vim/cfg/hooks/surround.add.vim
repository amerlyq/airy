let s:ad = '<Plug>(operator-surround-append)'
let s:rm = '<Plug>(operator-surround-delete)'
let s:ch = '<Plug>(operator-surround-replace)'

" BUG: in vimscript replace don't work for angle: <word> -> [<word>]
call Map_nxo('[Quote]a', s:ad, 'nx')
call Map_nxo('[Quote]d', s:rm, 'nx')
call Map_nxo('[Quote]r', s:ch, 'nx')

call Map_nxo('[Quote]dd', s:rm.'aW', 'nx')
call Map_nxo('[Quote]dD', s:rm.'ab', 'nx')

"" Word-based quoting (reversed by frecency)
call Map_nxo('[Quote]w', s:ad.'iW', 'n')
call Map_nxo('[Quote]W', s:ad.'iw', 'n')
" DEV: xmap 'qw..' -- add quotes to each word in selection
" call Map_nxo('[Quote]<Space>', s:ad.' ', 'x')

"" Spaces as special quotes
call Map_nxo('[Quote]<Space>', s:ad.'iw ', 'n')
call Map_nxo('[Quote]<Space>', s:ad.' ', 'x')

"" Add quotes on qq
call Map_nxo('[Quote]q', s:ad.'iW"', 'n')
call Map_nxo('[Quote]q', s:ad.'"', 'x')
call Map_nxo('[Quote]Q', s:ad.'iWQ', 'n')
call Map_nxo('[Quote]Q', s:ad.'Q', 'x')
call Map_nxo('[Quote]o', s:ad.'iWo', 'n')
call Map_nxo('[Quote]o', s:ad.'o', 'x')
call Map_nxo('[Quote]e', s:ad.'iWe', 'n')
call Map_nxo('[Quote]e', s:ad.'e', 'x')

"" Sigils for bash
call Map_nxo('[Quote]@', s:ad.'iw2', 'n')
call Map_nxo('[Quote]@', s:ad.'2', 'x')
call Map_nxo('[Quote]$', s:ad.'iw4', 'n')
call Map_nxo('[Quote]$', s:ad.'4', 'x')

"" Add brackets by v<motion>q[<aliases>]
call Map_blocks('[Quote]', s:ad, 'x', 'map')

"" Accents for *.nou
call Map_blocks('[Quote]', s:ad.'iW', 'n', 'map', '**;__;~~')
call Map_blocks('[Quote]', s:ad, 'x', 'map', '**;__;~~')
