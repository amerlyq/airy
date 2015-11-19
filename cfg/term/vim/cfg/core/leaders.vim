let g:mapleader = ','        " Use <Leader> in global plugins.
let g:maplocalleader = ',.'  " Use <LocalLeader> in filetype plugins.
" noremap <unique> <Leader> <Nop>
" noremap <unique> <LocalLeader> <Nop>

" NOTE more toggle prefixes: use <Leader>T[key] and <Leader>t<leader>[key]
" ALT ; m , + <Space>+ <C-Space> <Tab> <S-Tab> <Bar>
for [fr, to] in [['q', '[Quote]']]
  call Map_nxo(fr, to, 'nx') | call Map_nxo(to, '<Nop>', 'nx', 'noremap')
endfor
for [fr, to] in [['\', '[Frame]'], ['<Space>', '[Space]']]
  call Map_nxo(fr, to) | call Map_nxo(to, '<Nop>', 'nxo', 'noremap')
endfor
