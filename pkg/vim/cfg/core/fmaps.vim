"{{{1 Maps helpers ==========
fun! RetainPos(cmd)
  " ALT line("."), col(".")
  let l:pos = getcurpos()
  silent! exe a:cmd
  call setpos('.', l:pos)
endf


fun! Map_nxo(lhs, rhs, ...)
  let modes = get(a:, 1, 'nxo')   " =modes
  let augmt = get(a:, 2, 0)       " 0=unique, 1=augment, 2=override
  let mapcmd= get(a:, 3, 'map')   " map/noremap
  for m in split(modes, '\zs')
    " echo m.(a:0>0 ? a:1 : 'map').' <silent><unique> '. a:fr .' '. a:to
    if augmt==1 && mapcheck(a:lhs, m) !=# '' | continue |en
    try|exe join([m.mapcmd, '<silent>',
          \ (augmt==2 ? '' : '<unique>'), a:lhs, a:rhs])
    catch /^Vim\%((\a\+)\)\=:E227/
      echo v:exception
      verbose exe mapcmd.' '.a:lhs
    endt
  endfor
endfun


fun! Map_blocks(prefix, mapping, ...)
  for g in split(get(a:, 3, g:block_aliases), ';')
    for i in range(1, strlen(g)-1)
      " THINK: for k in ['', '[Space]', 'g[Space]', '<Leader>[Space]']
      call Map_nxo(a:prefix.g[i], a:mapping.g[0],
          \ get(a:, 1, 'ox'), 0, get(a:, 2, 'noremap'))
    endfor
  endfor
endf


"" Aliases to STD blocks by numbers
" [ai][wWps] -- whole word, paragraph, sentence itself
" [ai][()b{}B<>\[\]t'"`] -- content of *brackets*, tags, quotes
let g:block_aliases = '(()0;{{}9;[[]8;''''1;""2;<<>3'  ";$$4
for p in ['a', 'i']
  call Map_blocks(p, p, 'ox', 'noremap', '(0;{9;[8;"2;''1;<3')  ";`4
endfor


fun! Map_textobj(c, plug, ...)
  for g in ['a', 'i']
    let l:rhs = printf('<Plug>(textobj-%s-%s)', a:plug, (a:0>0? {a:1}(g) : g))
    call Map_nxo(g.a:c, l:rhs, 'ox')
  endfor
endf
