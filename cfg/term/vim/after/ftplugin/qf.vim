" TODO: http://vim.wikia.com/wiki/Fold_quickfix_list_on_directory_or_file_names

setlocal norelativenumber number
setlocal nowrap textwidth=0
" Don't pop up quickfix buffers when doing :bn or :bp
set nobuflisted

" are we in a location list or a quickfix list?
let b:isLoc = len(getloclist(0)) > 0 ? 1 : 0
let b:wPref = b:isLoc ? 'l' : 'c'

" force the qf wnd to be opened at the bottom and take the full width
wincmd J

"" Rule of Thumb: reuse editing mappings, and don't touch navigation
" q/<Space> - close / jump,
" o/O - preview/jump of and stay,        I - jump into and close,
" x/X - exchange to tab foregr/backgr,   S/H - split vert/horz,
let s:qf_mappings = {
      \ 'q' : ':#close<CR>',
      \ 'o' : '<CR><C-w>p',
      \ 'm' : '<CR><C-w>pj',
      \ 'O' : '<CR>',
      \ 'I' : '<CR><C-w><C-w>:#close<CR>',
      \ 'S' : '<C-w><CR><C-w>L<C-w>p<C-w>J<C-w>p',
      \ 'H' : '<C-W><CR><C-w>K<C-w>b',
      \ 'x' : '<C-w><CR><C-w>T',
      \ 'X' : '<C-w><CR><C-w>TgT<C-W><C-W>',
      \ '<Space>' : '<CR>',
      \ '<CR>' : '<CR>',
      \ 'gH' : ':#older<CR> 99',
      \ 'gL' : ':#newer<CR> 99',
      \ 'gh' : ':#older<CR>',
      \ 'gl' : ':#newer<CR>',
\ }

" SNIP: \ 'o' : '<CR>:#open<CR>',
      " \ 'S' : '<C-w><CR><C-w>H<C-W>b<C-W>J<C-W>t',
" inspired by Ack.vim
" nnoremap <buffer> s <C-w><CR>

let s:fmt_key = "nnoremap <buffer><nowait><silent> %s %s"
for [k, v] in items(s:qf_mappings)
  exe printf(s:fmt_key, k, substitute(v, '#', b:wPref, 'g'))
endfor

" FROM: https://github.com/thinca/vim-qfreplace/issues/5
" MAIN: https://github.com/romainl/dotvim/blob/master/bundle/qf/after/ftplugin/qf.vim
" filter the location/quickfix list :Filter foo
command! -buffer -nargs=* Filter call qf#FilterList(<q-args>)
nnoremap <silent> <buffer> § :Filter <C-r><C-f><CR>
" restore the location/quickfix list :Restore
command! -buffer Restore call qf#RestoreList()
nnoremap <silent> <buffer> <F5> :Restore<CR>
" do something on each line in the location/quickfix list :Doline s/^/---
command! -buffer -nargs=1 Doline call qf#DoList(1, <q-args>)
" do something on each file in the location/quickfix list :Dofile %s/^/---
command! -buffer -nargs=1 Dofile call qf#DoList(0, <q-args>)
