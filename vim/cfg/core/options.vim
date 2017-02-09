set cpoptions=aABceFIKsy
" c - search matches don't overlap
" F - set buffer name on write
" I - don't delete autoindent on <Up>/<Down>
" K - don't wait multichar keycode like <F1><F1> to complete
" y - repeat yank on '.'
" set cpoptions+=J  " Add for plain text ft -- like LaTeX and writing


set formatoptions=bclnoqr   " Coding/markup/outlining
" c - autowrap comments, inserting comment leader
" l - don't auto-wrap line if it was longer before insert
" n - recognize numbered lists
" o - continue comment marker in new lines
" q - allow formatting on gq
" r - insert comment leader on enter
" b - autowrap line only if inserted blank
if v:version >= 704
  set formatoptions+=j " remove a comment leader on join
endif
" set formatoptions+=mM     " Use for asian text
" set formatoptions+=at12  " Add for plain text ft -- like LaTeX and writing
" a - autoformat on text change
" t - autowrap text
" 1 - don't break with one-letter word at line end
" 2 - use paragraph indent from second line -- first is indented


" Disable menu.vim (must be before syntax/filetype on)
if has('gui_running')  " TODO TRY 'eg'; 'a' -- disabled because of 'copyq'
  set guioptions=Mc    " and use console-like dialogs instead of gui popup
" elseif exists('$DISPLAY')
endif


" TODO: chech if there are saved unallowable/unnecessary localoptions
" BAD: localoptions -- enforce wrong behaviour with 'vim-stay'
set viewoptions=cursor,folds,slash,unix   " What to save in :mkview
" localoptions - try to save foldexpr for ':Fs', etc between sessions
