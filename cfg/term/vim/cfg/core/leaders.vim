let g:mapleader = ','        " Use <Leader> in global plugins.
let g:maplocalleader = ',.'  " Use <LocalLeader> in filetype plugins.
" noremap <unique> <Leader> <Nop>
" noremap <unique> <LocalLeader> <Nop>

" NOTE more toggle prefixes: use <Leader>T[key] and <Leader>t<leader>[key]
" ALT ; m , + <Space>+ <C-Space> <Tab> <S-Tab> <Bar>

let s:leads = {'[Frame]': '\', '[Space]': '<Space>'}
for [to, fr] in items(s:leads)
  call Map_nxo(fr, to) | call Map_nxo(to, '<Nop>', 'nxo', 'noremap')
endfor

" EXPL: omap omitted for shortcut of '..q' textobj
let s:leads = {'[Quote]': 'q', '[Unite]': '<Tab>',
  \ '[Toggle]': '<Leader>t', '[Replace]': '<Leader>r', '[Git]': '[Frame]g'}
for [to, fr] in items(s:leads)
  call Map_nxo(fr, to, 'nx') | call Map_nxo(to, '<Nop>', 'nx', 'noremap')
endfor

" Restore original <C-i> behaviour
noremap <silent><unique> [Unite]<Tab>  <Tab>
