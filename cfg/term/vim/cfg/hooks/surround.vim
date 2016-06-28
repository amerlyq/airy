let s:alias = '(()0;{{}9;[[]8;''''1;""2;<<>3;``4'

for op in ['append', 'delete', 'replace']
  call Map_nxo('[Quote]'.op[0], '<Plug>(operator-surround-'.op.')', 'nx')
endfor

let s:op = '<Plug>(operator-surround-append)'

"" Add brackets on qq
call Map_nxo('[Quote]q', s:op.'iW"', 'n')
call Map_nxo('[Quote]q', s:op.'"', 'x')

"" Add brackets by v<motion>q[<aliases>]
call Map_blocks('[Quote]', s:op, 'x', 'map', s:alias)

"" Add brackets by qa<motion>[<aliases>]
let g:operator#surround#blocks = {'-': map(split(s:alias, ';'), "{
  \  'keys' : split(v:val[1:], '\\zs'),
  \  'block': split((v:val[0] =~ '[''`\"]' ? v:val[0:1] : v:val[1:2]), '\\zs'),
  \  'motionwise' : ['char', 'line', 'block'],
  \}") }


if dein#tap('vim-textobj-between')
  " Surrounding symbols for current cursor position (like 'f`')
  nmap <silent><unique> [Quote]f <Plug>(operator-surround-replace)<Plug>(textobj-between-a)
  nmap <silent><unique> [Quote]F <Plug>(operator-surround-delete)<Plug>(textobj-between-a)
endif


if dein#tap('vim-textobj-quotes')
  " Quoted (outer) expr is the most useful:
  omap <silent><unique> q aq
endif


if dein#tap('vim-textobj-anyblock')
  " CHECK: let b:textobj_anyblock_buffer_local_blocks = [ ':', '*' ]
  " Current enclosing block of ({["'<`
  nmap <silent><unique> [Quote]b <Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)
  nmap <silent><unique> [Quote]B <Plug>(operator-surround-delete)<Plug>(textobj-anyblock-a)
  " TODO:THINK:RFC: use getchar() instead of direct mappings?
  "   = Redirect if no such mappings exists (see inside op-surr src)
  let s:op = '<Plug>(operator-surround-replace)<Plug>(textobj-anyblock-a)'
  call Map_blocks('[Quote]', s:op, 'n', 'map', s:alias)
endif
