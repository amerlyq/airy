" NOTE more prefixes: use <Leader>T[key] and <Leader>t<leader>[key]
"
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
nmap <silent><unique> <Space> [Space]
xmap <silent><unique> <Space> [Space]
nnoremap <silent><unique> [Space] <Nop>
xnoremap <silent><unique> [Space] <Nop>
