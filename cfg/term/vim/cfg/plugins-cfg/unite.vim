if neobundle#tap('unite.vim') "{{{
  " [Unite]h help
  " -u outline
  " -n file/new
  " Replaces fuzzyfinder, recursive
  let s:maps = {
  \ 'f': 'files file_rec/async:!',
  \ 'F': 'files file',
  \ 'b': 'buffers -quick-match buffer bookmark',
  \ '/': 'grep grep:.',
  \ 'L': 'lines line',
  \ ';': 'commands command',
  \ ':': 'commands history/command',
  \ 'm': 'mrus file_mru',
  \ 'y': 'yanks history/yank',
  \ 'o': 'Outline outline',
  \}
  for [c, r] in items(s:maps) | for m in ['n','x']
    exe m.'noremap <unique><silent> [Unite]'.c
          \.' :Unite -buffer-name='.r.'<CR>'
  endfor| endfor
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/unite.vim'
  call neobundle#untap()
endif "}}}
