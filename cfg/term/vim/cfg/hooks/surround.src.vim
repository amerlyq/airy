"" Add brackets by qa<motion>[<aliases>]

" HACK:(overrides) remove '$$4' from g:block_aliases
" BAD: disabled 'spaced' brackets '{( ', ' )}'
let g:operator#surround#no_default_blocks = 1
let g:operator#surround#blocks = {'-': [
  \ {'block': ['${', '}'], 'motionwise': ['char', 'line'], 'keys': ['$', '4']}
  \] +
  \ map(split('();{};[]', ';'), "{
  \  'keys' : [v:val[0]],
  \  'block': [v:val[0].' ', ' '.v:val[1]],
  \  'motionwise' : ['char', 'line', 'block'],
  \ }") +
  \ map(split(g:block_aliases, ';')[:2], "{
  \  'keys' : split(v:val[-3:], '\\zs'),
  \  'block': split(v:val[-3:-2], '\\zs'),
  \  'motionwise' : ['char', 'line', 'block'],
  \ }") }
