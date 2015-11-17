" DEPRECATED: USE Unite.vim instead
" Symmetrical binding to 'gt' for buffers  (12gb -- open buffer 12)
nnoremap <unique> gb :<C-u><C-r>=(v:count? v:count.'b' : 'b#')<CR><CR>
" Toggle to last edited buffer/file
nnoremap <unique> [Frame]` :b#<CR>


" Set minimum window size to 79x8
set winheight=8
set winwidth=80

" magnifying when switching (more stable then 'hjkl<C-W>_' )
let g:magnify_on = 1
noremap <unique> <Leader>tm :<C-U>let g:magnify_on = !g:magnify_on  \|
      \ echo('  wmagnify = ' . (g:magnify_on ? 'on' : 'off'))<CR>
autocmd WinEnter * call AutoMagnifying()
function! AutoMagnifying()
  if g:magnify_on
    " BUG: bad when split screen -- need min(8, &lines-othersH)
    let &winminheight=min([&lines, 8])
    let &winminwidth=min([&columns, 15])
    resize 100    "or another big number
  endif
endfunc


" if winnr() > 1
" DISABLED: bugs
"   -- when winnr==1 resizes 'ex' line from 1 to bigger when up/down
"   -- on winnr==2 resizes windows by mouse instead of scrolling inside
" nnoremap <unique> <Up>    :resize +4<CR>
" nnoremap <unique> <Down>  :resize -4<CR>
" nnoremap <unique> <Left>  :vertical resize +4<CR>
" nnoremap <unique> <Right> :vertical resize -4<CR>
" endif

" Increment and decrement
" nnoremap + <C-a>
" nnoremap - <C-x>
" Navigate window
" nnoremap <C-x> <C-w>x
" nnoremap <expr><C-m> (bufname('%') ==# '[Command Line]' <bar><bar> &l:buftype ==# 'quickfix') ? "<CR>" : "<C-w>j"

" focus adjacent window
" nnoremap <A-PageUp> <C-W>W
" nnoremap <A-PageDown> <C-W>w
" split current window:  :vs, :sp

" collapse other windows
" nnoremap <Leader>0 <C-W><Bar><C-W>_
" all windows equal size
" nnoremap <Leader>9 <C-W>=
" close other windows
" nnoremap <Leader>1 <C-W>o
" close current window
" nnoremap <Leader>4 <C-W>c
