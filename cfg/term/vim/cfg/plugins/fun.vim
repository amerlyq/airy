""" Tools

"" CHECK: Ascii graph drawing in vim {{{1
call dein#add('vim-scripts/DrawIt', {
  \ 'on_cmd': 'DrawIt',
  \ 'on_map': '<Plug>DrawItStart'})


""" Games
"" CHECK: Hello Vimmer, welcome to the Dungeons of Doom... {{{1
call dein#add('katono/rogue.vim', {'if': 'has("lua")', 'on_cmd': 'Rogue'})
