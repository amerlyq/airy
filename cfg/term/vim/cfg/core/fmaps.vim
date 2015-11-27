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
    exe m.get(a:, 2, 'map').' <silent><unique> '. a:lhs .' '. a:rhs
  endfor
endfun


fun! Map_blocks(prefix, mapping, ...)
  let l:dfl = '(0;{9;[8;"2;''1;<3;`4'
  for g in split(get(a:, 3, l:dfl), ';') | for i in range(1, strlen(g)-1)
    " for k in ['', '[Space]', 'g[Space]', '<Leader>[Space]']
    call Map_nxo(a:prefix.g[i], a:mapping.g[0],
          \ get(a:, 1, 'ox'), get(a:, 2, 'noremap'))
  endfor | endfor
endf


fun! Map_textobj(c, plug, ...)
  for g in ['a', 'i']
    let l:rhs = printf('<Plug>(textobj-%s-%s)', a:plug, (a:0>0? {a:1}(g) : g))
    call Map_nxo(g.a:c, l:rhs, 'ox')
  endfor
endf
