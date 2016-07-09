"" Add brackets by qa<motion>[<aliases>]

" HACK: remove '$$4' from g:block_aliases
let g:operator#surround#blocks = {'-':
  \ map(split(g:block_aliases, ';')[:2], "{
  \  'keys' : split(v:val[1:], '\\zs'),
  \  'block': split(v:val[-3:-2], '\\zs'),
  \  'motionwise' : ['char', 'line', 'block'],
  \ }") + [
  \ {'block': ['${', '}'], 'motionwise': ['char', 'line'], 'keys': ['$', '4']}
  \ ]}
