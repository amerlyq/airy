if neobundle#tap('vim-fugitive')  " Fugitive: {{{1
  autocmd BufReadPost fugitive://* set bufhidden=delete
  nnoremap <silent><unique> [Frame]gs :Gstatus<CR>
  nnoremap <silent><unique> [Frame]gl :Glog<CR>
  nnoremap <silent><unique> [Frame]gd :Gdiff<CR>
  nnoremap <silent><unique> [Frame]gw :Gwrite<CR>
  nnoremap <silent><unique> [Frame]gb :Gblame<CR>
  call neobundle#untap()
endif


if neobundle#tap('gitv')  "{{{1
  nnoremap <silent><unique> [Frame]gv :Gitv  --all<CR>
  nnoremap <silent><unique> [Frame]gV :Gitv! --all<CR>
  xnoremap <silent><unique> [Frame]gV :Gitv! --all<CR>
  call neobundle#untap()
endif "}}}
