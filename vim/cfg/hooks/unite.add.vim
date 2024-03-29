" <S-Tab>
noremap <unique><silent> [Unite]<Space> :UniteResume<CR>
" NOTE: Replaces fuzzyfinder, recursive
nnoremap <silent><unique> [Unite]n  :UniteNext<CR>
nnoremap <silent><unique> [Unite]p  :UnitePrevious<CR>

let s:maps = {
\ 'b': 'buffers -quick-match buffer bookmark',
\ 'e': 'MyCmd mycmd',
\ 'f': 'files file_rec/async:!',
\ 'j': 'jumplist jump',
\ '*': 'Favourites menu',
\ 'M': 'Keybinds mapping',
\ 'm': 'mrus file_mru',
\ 'o': 'Outline outline',
\ 'q': 'Quickfix quickfix',
\ 's': 'UltiSnips ultisnips',
\ 'S': 'MySub mysub',
\ 'y': 'yanks history/yank',
\ 'g': 'grep grep:.',
\ ':': 'commands history/command',
\ ';': 'commands command',
\ 'F': 'files file',
\ 'T': 'tags tag',
\ '/': 'lines -start-insert line',
\ '?': 'help',
\}

for [c, r] in items(s:maps) | for m in ['n','x']
  exe m.'noremap <unique><silent> [Unite]'.c
        \.' :Unite -buffer-name='.r.'<CR>'
endfor | endfor
