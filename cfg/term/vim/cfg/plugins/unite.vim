""" United drop-down menus
" SEE: http://bling.github.io/blog/2013/06/02/unite-dot-vim-the-plugin-you-didnt-know-you-need/

"" CHECK Unite main sources {{{1
call dein#add('Shougo/neomru.vim', {'on_if': 1})
call dein#add('Shougo/neoyank.vim', {'on_if': 1, 'on_source': 'unite.vim'})



"" CHECK Auxiliary sources {{{1
call dein#add('Shougo/unite-outline', {'on_source': 'unite.vim'})
call dein#add('thinca/vim-unite-history', {'on_source': 'unite.vim'})
call dein#add('osyo-manga/unite-quickfix', {'on_source': 'unite.vim'})
call dein#add('tsukkee/unite-tag', {'on_source': 'unite.vim'})



"" CHECK Fast fuzzy access to List i-sources. Dependency of 'unite-*'. {{{1
" NOTE: [Unite]h help, -u outline, -n file/new
call dein#add('Shougo/unite.vim', {
  \ 'depends': 'neomru.vim',
  \ 'hook_source': 'call _cfg("unite/*.vim")'})

if dein#tap('unite.vim')
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
endif
