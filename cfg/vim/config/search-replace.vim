nohlsearch

set incsearch   " incremental search
set hlsearch    " highlight search results
set ignorecase  " make searching case insensitive
set smartcase   " ... unless the query has capital letters

" Amazing custom search command. Thansk to Ingo: http://stackoverflow.com/a/24818933/1147859
command! -nargs=+ Se execute 'vimgrep /' . [<f-args>][0] . '/ **/*.' . [<f-args>][1]
" set gdefault " assume the /g flag on :s substitutions to replace all matches in a line
" set autoread " Make Vim automatically open changed files (e.g. changed after a Git commit)

"" Make <C-L> (redraw screen) and turn off search highlighting until the next
"" search,  http://vim.wikia.com/wiki/Example_vimrc
nnoremap <C-l> :nohlsearch<CR><C-l>

" Suppress unity behaviour for my workflow
" vnoremap <Leader>/ <C-R>

" find merge conflict markers
nnoremap <Leader>! /\v^[<=>]{7}( <Bar>$)/<cr>


"noremap <leader>ct <Esc>:retab<CR>, :retab!
noremap <leader>ct :s:^\t\+:\=repeat(" ", len(submatch(0))*' . &ts . ')<CR>
noremap <leader>cT :s:^\( \{'.&ts.'\}\)\+:\=repeat("\t", len(submatch(0))/' . &ts . ')<CR>
": Remove empty lines
command -bar -range=% RemoveEmptyLines %s:.\n\zs\s*\n\ze.\|^\s*\n\s*\_$::
noremap <leader>cE :<C-U>RemoveEmptyLines<CR>`>

noremap <leader>cc :<C-U>%s:\<<C-R><C-W>\>:<C-R><C-W>:g<Left><Left>
noremap <leader>cC :s:\<<C-R><C-W>\>:<C-R><C-W>:g<Left><Left>
noremap <leader>cy <Esc>:%s:\<<C-R><C-W>\>:<C-R>0:g<Left><Left>
": Emulate 'tr' command -> vectored replacing of symbols
noremap <leader>cR :s/.*/\=tr(submatch(0), '()', '[]')

": Delete highlighted match
nnoremap <leader>cx :%s;;;g<CR>
vnoremap <leader>cx :s;;;g<CR>
