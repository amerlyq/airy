" Leader '\' {{{
let s:leader = g:mapleader
let mapleader = "\\"

if neobundle#tap('vim-fugitive')  " Fugitive: {{{1
  autocmd BufReadPost fugitive://* set bufhidden=delete
  nnoremap <silent> <unique> <leader>gs :Gstatus<CR>
  nnoremap <silent> <unique> <leader>gl :Glog<CR>
  nnoremap <silent> <unique> <leader>gd :Gdiff<CR>
  nnoremap <silent> <unique> <leader>gw :Gwrite<CR>
  nnoremap <silent> <unique> <leader>gb :Gblame<CR>
endif


if neobundle#tap('gitv')  " Gitv: {{{1
  nmap <silent> <unique> <leader>gv :Gitv --all<CR>
  nmap <silent> <unique> <leader>gV :Gitv! --all<CR>
  vmap <silent> <unique> <leader>gV :Gitv! --all<CR>
endif

let mapleader = s:leader  " }}}
