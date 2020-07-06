"" Add brackets by qa<motion>[<aliases>]

" HACK:(overrides) remove '$$4' from g:block_aliases
" BAD: disabled 'spaced' brackets '{( ', ' )}'
let g:operator#surround#no_default_blocks = 1
let g:operator#surround#blocks = {'-': [
  \ {'block': ['"${', '}"'],    'motionwise': ['char', 'line'], 'keys': ['4']},
  \ {'block': ['"${', '[@]}"'], 'motionwise': ['char', 'line'], 'keys': ['2']},
  \ {'block': ['${', '}'],      'motionwise': ['char', 'line'], 'keys': ['$']},
  \ {'block': ['${', '[@]}'],   'motionwise': ['char', 'line'], 'keys': ['@']},
  \ {'block': ['“', '”'],       'motionwise': ['char', 'line'], 'keys': ['q']},
  \ {'block': ['«', '»'],       'motionwise': ['char', 'line'], 'keys': ['Q']},
  \ {'block': ['>', '<'],       'motionwise': ['char', 'line'], 'keys': ['>']},
  \ {'block': ['·', '·'],       'motionwise': ['char', 'line'], 'keys': ['o']},
  \ {'block': ['⦅', '⦆'],       'motionwise': ['char', 'line'], 'keys': ['e']},
  \]
  \+map(split('();{};[]', ';'), "{
  \  'keys' : [v:val[1]],
  \  'block': [v:val[0].' ', ' '.v:val[1]],
  \  'motionwise' : ['char', 'line', 'block'],
  \ }")
  \+map(split(g:block_aliases, ';'), "{
  \  'keys' : [v:val[0], v:val[-1]],
  \  'block': split(v:val[-3:-2], '\\zs'),
  \  'motionwise' : ['char', 'line', 'block'],
  \ }")
  \+map(split('**;__;~~', ';'), "{
  \  'keys' : [v:val[1]],
  \  'block': [v:val[0], v:val[1]],
  \  'motionwise' : ['char', 'line', 'block'],
  \ }")
  \}
