" NOTE more prefixes: use <Leader>T[key] and <Leader>t<leader>[key]
" TODO consider using <Tab>, <S-Tab> in mappings, think about '|'
"     Also can be used for operator-pending, related to indent
"     <Space> also can be used for operator pending
"     All surround-insert by <Leader><Space>

let g:mapleader = ','        " ALT +,\<Space>+. Use <Leader> in global plugin.
let g:maplocalleader = ',.'  " Use <LocalLeader> in filetype plugin.
" noremap <unique> <Leader> <Nop>
" noremap <unique> <LocalLeader> <Nop>

" " Release keymappings for plug-in.
" nnoremap ;  <Nop>
" xnoremap ;  <Nop>
" nnoremap m  <Nop>
" xnoremap m  <Nop>
" nnoremap ,  <Nop>
" xnoremap ,  <Nop>


" For quote, etc
nmap <silent><unique> q [Quote]
xmap <silent><unique> q [Quote]
nnoremap <silent><unique> [Quote] <Nop>
xnoremap <silent><unique> [Quote] <Nop>

" For edit, inserts
" CamelMotion
nmap <silent><unique> <Space> [Space]
xmap <silent><unique> <Space> [Space]
nnoremap <silent><unique> [Space] <Nop>
xnoremap <silent><unique> [Space] <Nop>

" For rarely used plugins/frameworks
nmap <silent><unique> \ [Frame]
xmap <silent><unique> \ [Frame]
nnoremap <silent><unique> [Frame] <Nop>
xnoremap <silent><unique> [Frame] <Nop>
