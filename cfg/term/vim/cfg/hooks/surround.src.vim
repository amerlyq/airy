"" Add brackets by qa<motion>[<aliases>]

let g:operator#surround#blocks = {'-': map(split(g:block_aliases, ';'), "{
  \  'keys' : split(v:val[1:], '\\zs'),
  \  'block': split((v:val[0] =~ '[''`\"]' ? v:val[0:1] : v:val[1:2]), '\\zs'),
  \  'motionwise' : ['char', 'line', 'block'],
  \}") }
