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
vnoremap <unique> [Replace]s :<C-U>%s;\V<C-R>=GetVisualSelection("")<CR>;;g<CR><Left><Left>
" Replace last patt by current vsel
" vnoremap <unique> <Leader>cv :<C-U>%s;;<C-R>=GetVisualSelection("")<CR>;g<CR>
" UNUSED: Emulate 'tr' command -> vectored replacing of symbols
" noremap <unique> <leader>cR :s/.*/\=tr(submatch(0), '()', '[]')

" DEV:TODO: merge with vim-over definitions to exterminate duplicates
" DEV: '21,c': v:count for ',c' -- \2\1, use <expr> mapping, add backslash
" BUG: adds visual markers '<, '> before subs.
fun! SubsCount()
  let rhs = (v:count ? substitute(string(v:count), '.', '\\&', 'g') : '')
  return l:rhs
endfun

let s:subs = {
\ '<Leader>c' : 's;;<C-r>=SubsCount()<CR>;g<Left><Left>',
\ '<Leader>C' : 'g//',
\ '<Leader>R' : 'v//',
\ '[Replace]w': 's::<C-r><C-w>:g<Left><Left>',
\ '[Replace]y': 's::<C-r>":g<Left><Left>',
\ '[Replace]+': 's::<C-r>+:g<Left><Left>',
\ '[Replace]m': 's;;<C-r>/;g<Left><Left>',
\ '[Replace]v': '<C-u>s;;<C-r>=GetVisualSelection(" ")<CR>;g<Left><Left>',
\ '[Replace]e': 's;;;g<CR>',
\ '[Replace]d': 'g//d<CR>',
\ '[Replace]f': 'v//d<CR>',
\} " norm!, etc
for [c, r] in items(s:subs)
  if maparg(c) ==# '' | for m in ['n','x']
    exe m.'noremap <unique> '.c.' :'.(m=='n'?'%':'').r
endfor | endif | endfor
