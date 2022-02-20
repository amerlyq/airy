"" Add brackets by qa<motion>[<aliases>]

" HACK:(overrides) remove '$$4' from g:block_aliases
" BAD: disabled 'spaced' brackets '{( ', ' )}'
let g:operator#surround#no_default_blocks = 1
let g:operator#surround#blocks = {'-': [
  \ {'block': ['"${', '}"'],    'motionwise': ['char'], 'keys': ['4']},
  \ {'block': ['"${', '[@]}"'], 'motionwise': ['char'], 'keys': ['2']},
  \ {'block': ['${', '}'],      'motionwise': ['char'], 'keys': ['$']},
  \ {'block': ['${', '[@]}'],   'motionwise': ['char'], 'keys': ['@']},
  \ {'block': ['“', '”'],       'motionwise': ['char', 'line'], 'keys': ['q']},
  \ {'block': ['«', '»'],       'motionwise': ['char'], 'keys': ['Q']},
  \ {'block': ['>', '<'],       'motionwise': ['char'], 'keys': ['>']},
  \ {'block': ['·', '·'],       'motionwise': ['char'], 'keys': ['o']},
  \ {'block': ['⦅', '⦆'],       'motionwise': ['char'], 'keys': ['x']},
  \ {'block': ['⸢', '⸥'],       'motionwise': ['char'], 'keys': ['e']},
  \ {'block': ['⦏', '⦐'],       'motionwise': ['char'], 'keys': ['B']},
  \ {'block': ['【', '】'],     'motionwise': ['char'], 'keys': ['m']},
  \ {'block': ['<b>', '</b>'],  'motionwise': ['char', 'line'], 'keys': ['b']},
  \ {'block': ['<i>', '</i>'],  'motionwise': ['char', 'line'], 'keys': ['i']},
  \ {'block': ['<u>', '</u>'],  'motionwise': ['char', 'line'], 'keys': ['u']},
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
