"{{{1 Maps helpers ==========
fun! RetainPos(cmd)
  " ALT line("."), col(".")
  let l:pos = getcurpos()
  silent! exe a:cmd
  call setpos('.', l:pos)
endf


fun! Map_nxo(lhs, rhs, ...)
  for m in split(a:0>0 ? a:1 : 'nxo', '\zs')
    " echo m.(a:0>0 ? a:1 : 'map').' <silent><unique> '. a:fr .' '. a:to
    exe m.(a:0>1 ? a:2 : 'map').' <silent><unique> '. a:lhs .' '. a:rhs
  endfor
endfun


fun! Map_block(prefix, mapping, mode)
  let l:bchars = ['()0', '{}9', '[]8', '"2', "'1", '<>3.', '`4']
  for cg in l:bchars | for c in split(cg, '\zs')
    " for k in ['', '[Space]', 'g[Space]', '<Leader>[Space]']
    call Map_nxo(a:prefix.c, a:mapping.cg[0], a:mode)
  endfor | endfor
endf


fun! Map_textobj(c, plug, ...)
  for g in ['a', 'i']
    let l:rhs = printf('<Plug>(textobj-%s-%s)', a:plug, (a:0>0? {a:1}(g) : g))
    call Map_nxo(g.a:c, l:rhs, 'ox')
  endfor
endf
