let g:mapleader = ','        " Use <Leader> in global plugins.
let g:maplocalleader = ',.'  " Use <LocalLeader> in filetype plugins.
" noremap <unique> <Leader> <Nop>
" noremap <unique> <LocalLeader> <Nop>

" NOTE more toggle prefixes: use <Leader>T[key] and <Leader>t<leader>[key]
" ALT ; m , + <Space>+ <C-Space> <Tab> <S-Tab> <Bar>
"MPogoda thinks it's better change <Leader> L '-'


" EXPL: omap omitted for shortcut of '..q' textobj
let s:leads = {
  \'nxo': {
  \  'Frame': '\',
  \  'Space': '<Space>',
  \ },
  \'nx': {
  \  'Quote': 'q',
  \  'Unite': '<Tab>',
  \  'Toggle' : '<Leader>t',
  \  'Replace': '<Leader>r',
  \  'Git': '[Frame]g',
  \}}

" ATTENTION:
" If you need upper-case maps ([U [S ...) -- then use '[^Space]'
"   = But you need replace prefix everywhere in vimrc with new '[^Space]'
" If '^' sub-prefix has conflicts, use instead '<C-^>'.
"   = However, it become even harder to type when manually searching by :map

for [M, maps] in items(s:leads)
  for [L, K] in items(maps)
    let L = '['.L.']'
    call Map_nxo(K, L, M)
    call Map_nxo(L, '<Nop>', M, 'noremap')
  endfor
endfor

" Restore original <C-i> behaviour
noremap <silent><unique> [Unite]<Tab>  <Tab>
