""" Tools

"" CHECK: Ascii graph drawing in vim {{{1
call dein#add('vim-scripts/DrawIt', {
  \ 'on_cmd': 'DrawIt',
  \ 'on_map': '<Plug>DrawIt'})

if dein#tap('DrawIt')
  map <unique> [Unite]DI  <Plug>DrawItStart
  map <unique> [Unite]DS  <Plug>DrawItStop
  map <unique> [Unite]Dsw <Plug>SaveWinPosn
  map <unique> [Unite]Drw <Plug>RestoreWinPosn
endif


"" Lingr -- remote workplace chat
" repo = 'basyura/J6uil.vim'
" depends = 'webapi-vim'
" hook_source = 'source ~/.vim/rc/plugins/J6uil.rc.vim'


""" Games

"" CHECK: Hello Vimmer, welcome to the Dungeons of Doom... {{{1
call dein#add('katono/rogue.vim', {'if': 'has("lua")', 'on_cmd': 'Rogue'})
