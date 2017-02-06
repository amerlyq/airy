" <S-Tab>
noremap <unique><silent> [Unite]<Space> :UniteResume<CR>
" NOTE: Replaces fuzzyfinder, recursive
nnoremap <silent><unique> [Unite]n  :UniteNext<CR>
nnoremap <silent><unique> [Unite]p  :UnitePrevious<CR>

let s:maps = {
\ 'b': 'buffers -quick-match buffer bookmark',
\ 'e': 'MyCmd mycmd',
\ 'f': 'files file_rec/async:!',
\ 'm': 'Favourites menu',
\ 'M': 'mrus file_mru',
\ 'o': 'Outline outline',
\ 's': 'MySub mysub',
\ 'y': 'yanks history/yank',
\ 'g': 'grep grep:.',
\ ':': 'commands history/command',
\ ';': 'commands command',
\ 'F': 'files file',
\ '/': 'lines -start-insert line',
\}

for [c, r] in items(s:maps) | for m in ['n','x']
  exe m.'noremap <unique><silent> [Unite]'.c
        \.' :Unite -buffer-name='.r.'<CR>'
endfor | endfor
