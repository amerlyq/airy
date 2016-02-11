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
nnoremap <unique> [Toggle]H :setl hlsearch! hls?<CR>
nnoremap <unique> <C-l> :nohlsearch<CR><C-l>

" Amazing custom search command. Thansk to Ingo: http://stackoverflow.com/a/24818933/1147859
command! -nargs=+ Se execute 'vimgrep /' . [<f-args>][0] . '/ **/*.' . [<f-args>][1]
command! -nargs=0 -range  SortInLine
      \ <line1>,<line2>call setline('.',join(sort(split(getline('.'),' ')),' '))
" Visual block sorting. Restore text _outside_ block:  gvyugvp
command! -bar -bang -range  SortByBlock
      \ <line1>,<line2>sort<bang> i /\ze\%V/

" Search opened buffers
" http://vim.wikia.com/wiki/Search_using_quickfix_to_list_occurrences
" :bufdo vimgrepadd threading % | copen

" find merge conflict markers -- DEPRECATED by textobj-conflict
" nnoremap <unique> <Leader>! /\v^[<=>]{7}( <Bar>$)/<cr>

" Find next character from under cursor (TODO? replace with [% and ]%?)
noremap <unique> gs :norm! <C-R>=v:count1<CR>f<C-R>=getline('.')[col('.')-1]<CR><CR>
noremap <unique> gS :norm! <C-R>=v:count1<CR>F<C-R>=getline('.')[col('.')-1]<CR><CR>

" UNUSED: Emulate 'tr' command -> vectored replacing of symbols
" noremap <unique> <leader>cR :s/.*/\=tr(submatch(0), '()', '[]')
