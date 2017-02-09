if &cp||exists('g:loaded_cinsert')|finish|else|let g:loaded_cinsert=1|endif
" Suppress move-left of cursor when leaving insert mode
"   http://vim.wikia.com/wiki/Prevent_escape_from_moving_the_cursor_one_character_to_the_left


augroup CursorBehaviour
  autocmd!
  au InsertEnter  * let b:CursorColumnI = col('.')  " Position in INSERT
  au CursorMovedI * let b:CursorColumnI = col('.')
  au InsertLeave  * if b:CursorColumnI != col('.') | call cursor(0, col('.')+1) | endif
augroup END
