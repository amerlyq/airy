nohlsearch

set incsearch   " incremental search
set hlsearch    " highlight search results
set ignorecase  " make searching case insensitive
set smartcase   " ... unless the query has capital letters
set wrapscan    " Searches wrap around the end of the file.
" set gdefault  " assume the /g flag on :s substitutions to replace all matches in a line
" set autoread  " Make Vim automatically open changed files (e.g. changed after a Git commit)

"" Make <C-L> (redraw screen) and turn off search highlighting until the next
"" search,  http://vim.wikia.com/wiki/Example_vimrc
nnoremap <unique> <Leader>tH :setl hlsearch! hls?<CR>
nnoremap <unique> <C-l> :nohlsearch<CR><C-l>


" Amazing custom search command. Thansk to Ingo: http://stackoverflow.com/a/24818933/1147859
command! -nargs=+ Se execute 'vimgrep /' . [<f-args>][0] . '/ **/*.' . [<f-args>][1]
command! -nargs=0 -range SortLine <line1>,<line2>call setline('.',join(sort(split(getline('.'),' ')),' '))
" Visual block sorting. Restore text _outside_ block:  gvyugvp
command! -range SortBlock <line1>,<line2>sort i /\ze\%V/


" Suppress unity behaviour for my workflow
" vnoremap <Leader>/ <C-R>
" find merge conflict markers
nnoremap <unique> <Leader>! /\v^[<=>]{7}( <Bar>$)/<cr>

" Find next character from under cursor (TODO replace with [% and ]%)
noremap <unique> gs :norm <C-R>=v:count1<CR>f<C-R>=getline('.')[col('.')-1]<CR><CR>
noremap <unique> gS :norm <C-R>=v:count1<CR>F<C-R>=getline('.')[col('.')-1]<CR><CR>


": Substitute current match
" nnoremap <leader>cw :%s:\<<C-R><C-w>\>:<C-R><C-w>:g<Left><Left>
nnoremap <unique> <Leader>c/ :%s::<C-R>/:g<Left><Left>
vnoremap <unique> <Leader>c/  :s::<C-R>/:g<Left><Left>
": Replace by yanked/deleted text
nnoremap <unique> <Leader>cy :%s::<C-R>":g<Left><Left>
vnoremap <unique> <Leader>cy  :s::<C-R>":g<Left><Left>
": Replace highlighted match (REPLACED by OverCommandLine)
if maparg('<Leader>cc') ==# ''
  nnoremap <unique> <Leader>cc :%s;;;g<Left><Left>
  vnoremap <unique> <Leader>cc  :s;;;g<Left><Left>
endif
if maparg('<Leader>cm') ==# ''
  nnoremap <unique> <Leader>cm :%s;;<C-r>/;g<Left><Left>
  vnoremap <unique> <Leader>cm  :s;;<C-r>/;g<Left><Left>
endif
": Delete highlighted match
nnoremap <unique> <Leader>cd :%s;;;g<CR>
vnoremap <unique> <Leader>cd  :s;;;g<CR>

"Sfx: s///g<Left><Left>, 'norm '
nnoremap <unique> <Leader>cX :%g//
vnoremap <unique> <Leader>cX  :g//
nnoremap <unique> <Leader>cV :%v//
vnoremap <unique> <Leader>cV  :v//

nnoremap <unique> <Leader>cx :%g//d<CR>
vnoremap <unique> <Leader>cx  :g//d<CR>
nnoremap <unique> <Leader>cv :%v//d<CR>
vnoremap <unique> <Leader>cv  :v//d<CR>

" Replace current vsel
vnoremap <unique> <Leader>cs :<C-U>%s;\V<C-R>=GetVisualSelection("")<CR>;;g<CR><Left><Left>
" Replace last patt by current vsel
" vnoremap <unique> <Leader>cv :<C-U>%s;;<C-R>=GetVisualSelection("")<CR>;g<CR>

" Search opened buffers
" http://vim.wikia.com/wiki/Search_using_quickfix_to_list_occurrences
" :bufdo vimgrepadd threading % | copen

": Emulate 'tr' command -> vectored replacing of symbols
noremap <unique> <leader>cR :s/.*/\=tr(submatch(0), '()', '[]')
