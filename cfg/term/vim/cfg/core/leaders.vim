" NOTE more toggle prefixes: use <Leader>T[key] and <Leader>t<leader>[key]
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

fun! s:MapLeader(fr, to)
  for c in ['n', 'x', 'o']
    exe c  .  'map <silent><unique> '. a:fr .' '. a:to
    exe c.'noremap <silent><unique> '. a:to .' <Nop>'
  endfor
endfun

call s:MapLeader('\', '[Frame]')
call s:MapLeader('q', '[Qoute]')
call s:MapLeader('<Space>', '[Space]')
