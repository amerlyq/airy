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

" Search opened buffers
" http://vim.wikia.com/wiki/Search_using_quickfix_to_list_occurrences
" :bufdo vimgrepadd threading % | copen

" find merge conflict markers -- DEPRECATED by textobj-conflict
nnoremap <unique> <Leader>! /\v^[<=>]{7}( <Bar>$)/<cr>

" Find next character from under cursor (TODO? replace with [% and ]%?)
noremap <unique> gs :norm! <C-R>=v:count1<CR>f<C-R>=getline('.')[col('.')-1]<CR><CR>
noremap <unique> gS :norm! <C-R>=v:count1<CR>F<C-R>=getline('.')[col('.')-1]<CR><CR>


" Replace current vsel (OR:THINK: nnoremap for last vsel by gv?)
vnoremap <unique> <Leader>cs :<C-U>%s;\V<C-R>=GetVisualSelection("")<CR>;;g<CR><Left><Left>
" Replace last patt by current vsel
" vnoremap <unique> <Leader>cv :<C-U>%s;;<C-R>=GetVisualSelection("")<CR>;g<CR>
": Emulate 'tr' command -> vectored replacing of symbols
noremap <unique> <leader>cR :s/.*/\=tr(submatch(0), '()', '[]')


": NOTE: some are replaced by vim-over
let s:subs = {
\ 'c': 's;;;g<Left><Left>',
\ 'w': 's::<C-r><C-w>:g<Left><Left>',
\ 'y': 's::<C-r>":g<Left><Left>',
\ 'm': 's;;<C-r>/;g<Left><Left>',
\ 'g': 'g//',
\ 'v': 'v//',
\ 'x': 's;;;g<CR>',
\ 'd': 'g//d<CR>',
\ 'f': 'v//d<CR>',
\} " norm!, etc
for [c, r] in items(s:subs)
  if maparg('<Leader>c'.c) ==# '' | for m in ['n','x']
    exe m.'noremap <unique> <Leader>c'.c.' :'.(m=='n'?'%':'').r
endfor | endif | endfor
