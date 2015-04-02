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


": Ag working dir  searching
" nnoremap <unique> <Leader>* :<C-U>Ag '<C-R>/'<CR>
nnoremap <unique> <Leader>a :<C-U>Ag -w '<C-R><C-W>'<CR>
vnoremap <unique> <Leader>a :<C-U>Ag -Q '<C-R>=GetVisualSelection(" ")<CR>'<CR>
": Ag buffer search
nnoremap <unique> g<Leader>a :<C-U>AgBuffer -w '<C-R><C-W>'<CR>
vnoremap <unique> g<Leader>a :<C-U>AgBuffer -Q '<C-R>=GetVisualSelection(" ")<CR>'<CR>
": Ag current file searching (currently no jumping -- need Ag >= 0.25 with --vimgrep)
nnoremap <unique> <Leader>A :<C-U>Ag -w '<C-R><C-W>' %:p<CR>
vnoremap <unique> <Leader>A :<C-U>Ag -Q '<C-R>=GetVisualSelection(" ")<CR>' %:p<CR>


": Substitute current match
" nnoremap <leader>cw :%s:\<<C-R><C-w>\>:<C-R><C-w>:g<Left><Left>
nnoremap <unique> <Leader>c/ :%s::<C-R>/:g<Left><Left>
vnoremap <unique> <Leader>c/  :s::<C-R>/:g<Left><Left>
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

