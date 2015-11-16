set hidden      " lets you switch buffers without saving
set splitright  " focus new window after vertical splitting
set splitbelow  " focus new window after horizontal splitting

" Set minimum window size to 79x8
set winheight=8
set winwidth=80

" switching
noremap <unique> zh  <C-W>h
noremap <unique> zj  <C-W>j
noremap <unique> zk  <C-W>k
noremap <unique> zl  <C-W>l

" Move between folds
noremap <unique> zJ  zj
noremap <unique> zK  zk

" switch to adjacent buffer in current window
noremap <unique> gh  :<C-U>bprev<CR>
noremap <unique> gl  :<C-U>bnext<CR>
noremap <unique> gH  :<C-U>bfirst<CR>
noremap <unique> gL  :<C-U>blast<CR>

" Use on each window of split, to scroll in sync
nnoremap <unique> <Leader>tb :setl scrollbind! scb?<CR>

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
" split current window
" :vs, :sp

" collapse other windows
" nnoremap <Leader>0 <C-W><Bar><C-W>_
" all windows equal size
" nnoremap <Leader>9 <C-W>=
" close other windows
" nnoremap <Leader>1 <C-W>o
" close current window
" nnoremap <Leader>4 <C-W>c


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


let s:leader = g:mapleader | let mapleader = "\\"  "{{{

" Symmetrical binding to 'gt' for buffers  (12gb -- open buffer 12)
nnoremap <unique> gb :<C-U><C-R>=v:count1<CR>b<CR>

" Toggle to last edited buffer/file
nnoremap <unique> <leader>` :b#<CR>

" if ! neobundle#tap('vim-airline')
"   for idx in range(1,10)
"     " Direct pick tab on <M-\d> or buffer on <leader>\d
"     " REMOVED: exec "nnoremap <unique> <M-". string(idx % 10) ."> ". idx ."gt"
"     exec "nmap <unique> <leader>". string(idx % 10) ."  ". idx ."gb"
"   endfor
" endif

let mapleader = s:leader  " }}}
