" BUG: don't work as expected? What it must to do at all?
" USAGE:HACK: Change filetype for opened region ':NN awk'
" command! -nargs=* -bang -range -complete=filetype NN
"     \ :<line1>,<line2> call nrrwrgn#NrrwRgn('',<q-bang>)
"     \ | setl filetype=<args>

" USAGE:HACK: Filter by pattern and open in split
" NOTE: hide comments (temporary strip) by ':v/^#/NRP'
for [c, r] in [['n', 'g//NRP<CR>:NRM<CR>'], ['N', 'v//NRP<CR>:NRM<CR>']]
  for m in ['n','x']
    exe m.'noremap <silent><unique> [Frame]'.c.' :'.(m=='n'?'%':'').r
  endfor
endfor

" Operator to select region in split 'n', or in current buffer
for [c, op] in items({'n': 'Do', 'N': 'BangDo'})
  call Map_nxo('<Leader>'.c, '<Plug>Nrrwrgn'.op)
endfor
