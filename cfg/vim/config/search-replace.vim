nohlsearch

set incsearch   " incremental search
set hlsearch    " highlight search results
set ignorecase  " make searching case insensitive
set smartcase   " ... unless the query has capital letters
" set gdefault  " assume the /g flag on :s substitutions to replace all matches in a line
" set autoread  " Make Vim automatically open changed files (e.g. changed after a Git commit)

"" Make <C-L> (redraw screen) and turn off search highlighting until the next
"" search,  http://vim.wikia.com/wiki/Example_vimrc
nnoremap <unique> <C-l> :nohlsearch<CR><C-l>


" Amazing custom search command. Thansk to Ingo: http://stackoverflow.com/a/24818933/1147859
command! -nargs=+ Se execute 'vimgrep /' . [<f-args>][0] . '/ **/*.' . [<f-args>][1]

" Suppress unity behaviour for my workflow
" vnoremap <Leader>/ <C-R>
" find merge conflict markers
nnoremap <unique> <Leader>! /\v^[<=>]{7}( <Bar>$)/<cr>


": Substitute current match
" nnoremap <leader>cw :%s:\<<C-R><C-w>\>:<C-R><C-w>:g<Left><Left>
nnoremap <unique> <Leader>cm :%s::<C-R>/:g<Left><Left>
vnoremap <unique> <Leader>cm  :s::<C-R>/:g<Left><Left>
": Replace by yanked/deleted text
nnoremap <unique> <Leader>cy :%s::<C-R>":g<Left><Left>
vnoremap <unique> <Leader>cy  :s::<C-R>":g<Left><Left>
": Replace highlighted match
nnoremap <unique> <Leader>cr :%s;;;g<Left><Left>
vnoremap <unique> <Leader>cr  :s;;;g<Left><Left>
": Delete highlighted match
nnoremap <unique> <Leader>cx :%s;;;g<CR>
vnoremap <unique> <Leader>cx  :s;;;g<CR>

vnoremap <unique> <Leader>cv :<C-U>%s;;<C-R>=GetVisualSelection("")<CR>;g<CR>


": Remove empty lines
command -bar -range=% RemoveEmptyLines <line1>,<line2>s:.\n\zs\s*\n\ze.\|^\s*\n\s*\_$::
noremap <unique> <leader>cE :<C-U>RemoveEmptyLines<CR>`>
": Emulate 'tr' command -> vectored replacing of symbols
noremap <unique> <leader>cR :s/.*/\=tr(submatch(0), '()', '[]')
"noremap <leader>ct <Esc>:retab<CR>, :retab!
noremap <unique> <leader>ct :s:^\t\+:\=repeat(" ", len(submatch(0))*' . &ts . ')<CR>
noremap <unique> <leader>cT :s:^\( \{'.&ts.'\}\)\+:\=repeat("\t", len(submatch(0))/' . &ts . ')<CR>

