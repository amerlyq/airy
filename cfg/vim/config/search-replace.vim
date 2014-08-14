nohlsearch

set incsearch   " incremental search
set hlsearch    " highlight search results
set ignorecase  " make searching case insensitive
set smartcase   " ... unless the query has capital letters

" make <C-L> (redraw screen) also turn off
" search highlighting until the next search
" http://vim.wikia.com/wiki/Example_vimrc
nnoremap <C-l> :nohlsearch<cr><C-l>

" list all occurrences of word under cursor in current buffer
"nnoremap <Leader>* [I
vnoremap <Leader>/ <C-R>

" find merge conflict markers
nnoremap <Leader>! /\v^[<=>]{7}( <Bar>$)/<cr>



"noremap <leader>ct <Esc>:retab<CR>, :retab!
noremap <leader>ct :s:^\t\+:\=repeat(" ", len(submatch(0))*' . &ts . ')<CR>
noremap <leader>cT :s:^\( \{'.&ts.'\}\)\+:\=repeat("\t", len(submatch(0))/' . &ts . ')<CR>
noremap <leader>ce :<C-U>%s:^\s*$\n::<CR>
noremap <leader>cc :<C-U>%s:\<<C-R><C-W>\>:<C-R><C-W>:g<Left><Left>
noremap <leader>cC :s:\<<C-R><C-W>\>:<C-R><C-W>:g<Left><Left>
noremap <leader>cy <Esc>:%s:\<<C-R><C-W>\>:<C-R>0:g<Left><Left>
":s;|;\\^M|;g  | split pipe on multiline


