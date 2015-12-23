" TODO: http://vim.wikia.com/wiki/Fold_quickfix_list_on_directory_or_file_names

setlocal number |try|set norelativenumber|catch/E518/|endt
setlocal nowrap textwidth=0
" Don't pop up quickfix buffers when doing :bn or :bp
set nobuflisted

" are we in a location list or a quickfix list?
" SEE http://vim-dev.vim.narkive.com/kbQnvYDR/we-can-t-handle-type-which-it-s-quickfix-or-location-list
let b:isLoc = len(getloclist(0)) > 0 ? 1 : 0
let b:wPref = b:isLoc ? 'l' : 'c'

" force the qf wnd to be opened at the bottom and take the full width
wincmd J

"" Rule of Thumb: reuse editing mappings, and don't touch navigation
" q/<Space> - close / jump,
" o/O - preview/jump of and stay,        I - jump into and close,
" x/X - exchange to tab foregr/backgr,   S/H - split vert/horz,
" \ 'o' : '',
fun! s:open_stay()
  let l:w = bufwinnr("%")
  exe 'norm!' "\<CR>"
  exe l:w.'wincmd w'
endf

let s:qf_mappings = {
      \ 'q' : ':#close<CR>',
      \ 'o' : ':call <SID>open_stay()<CR>',
      \ 'm' : '<CR><C-w>pj',
      \ 'O' : '<CR>',
      \ 'I' : '<CR><C-w><C-w>:#close<CR>',
      \ 'S' : '<C-w><CR><C-w>L<C-w>p<C-w>J<C-w>p',
      \ 'H' : '<C-W><CR><C-w>K<C-w>b',
      \ 'x' : '<C-w><CR><C-w>T',
      \ 'X' : '<C-w><CR><C-w>TgT<C-W><C-W>',
      \ 'gH' : ':try\| #older 99 \|catch/E380/\|endtry<CR>',
      \ 'gL' : ':try\| #newer 99 \|catch/E381/\|endtry<CR>',
      \ 'gh' : ':try\| #older    \|catch/E380/\|endtry<CR>',
      \ 'gl' : ':try\| #newer    \|catch/E381/\|endtry<CR>',
      \ '<CR>' : '<CR>',
      \ '<Space>' : '<CR>',
\ }

" SNIP: \ 'o' : '<CR>:#open<CR>',
      " \ 'S' : '<C-w><CR><C-w>H<C-W>b<C-W>J<C-W>t',
" inspired by Ack.vim
" nnoremap <buffer> s <C-w><CR>

let s:fmt_key = "nnoremap <buffer><nowait><silent> %s %s"
for [k, v] in items(s:qf_mappings)
  exe printf(s:fmt_key, k, substitute(v, '#', b:wPref, 'g'))
endfor

" MAIN: https://github.com/romainl/dotvim/blob/master/bundle/qf/after/ftplugin/qf.vim
" filter the location/quickfix list :Filter foo
command! -buffer -nargs=* Filter call qf#FilterList(<q-args>)
nnoremap <silent> <buffer> <F4> :Filter <C-r><C-f><CR>
" restore the location/quickfix list :Restore
command! -buffer Restore call qf#RestoreList()
nnoremap <silent> <buffer> <F5> :Restore<CR>
" do something on each line in the location/quickfix list :Doline s/^/---
command! -buffer -nargs=1 Doline call qf#DoList(1, <q-args>)
" do something on each file in the location/quickfix list :Dofile %s/^/---
command! -buffer -nargs=1 Dofile call qf#DoList(0, <q-args>)

" SEE more stable solution
"   https://github.com/thinca/vim-qfreplace/issues/5
" if exists('s:processing') | finish | endif
" let s:processing = 1
" let listbufnr = bufnr("%")
" let numwindows = winnr('$')
" let altwin = winnr('#')
" let curwin = winnr()
" copen
" if curwin == winnr()
"   call setbufvar(listbufnr, 'isQuickfix', '1')
" endif
" " close the quickfix list if it was closed when we began
" if numwindows != winnr('$')
"   cclose
" endif
" " return to quickfix/location list
" exe altwin 'wincmd w'
" exe curwin 'wincmd w'
" unlet s:processing
