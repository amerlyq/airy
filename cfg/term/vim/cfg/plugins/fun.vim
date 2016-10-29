""" Tools

"" CHECK: Ascii graph drawing in vim {{{1
call dein#add('vim-scripts/DrawIt', {
  \ 'on_cmd': 'DrawIt',
  \ 'on_map': '<Plug>DrawIt',
  \ 'hook_add': "
\\n   map <unique> [Unite]DI  <Plug>DrawItStart
\\n   map <unique> [Unite]DS  <Plug>DrawItStop
\\n   map <unique> [Unite]Dsw <Plug>SaveWinPosn
\\n   map <unique> [Unite]Drw <Plug>RestoreWinPosn
\"})



" Map: <LocalLeader>l[lvi]
call dein#add('wannesm/wmgraphviz.vim', {
  \ 'on_cmd': ['GraphvizCompile', 'GraphvizShow', 'GraphvizInteractiv'],
  \ 'on_map': '<LocalLeader>l',
  \ 'on_ft': 'dot'
  \})



"" Lingr -- remote workplace chat
" repo = 'basyura/J6uil.vim'
" depends = 'webapi-vim'
" hook_source = 'source ~/.vim/rc/plugins/J6uil.rc.vim'


""" Games

"" CHECK: Hello Vimmer, welcome to the Dungeons of Doom... {{{1
call dein#add('katono/rogue.vim', {
  \ 'if': 'has("lua")',
  \ 'on_cmd': 'Rogue'})
