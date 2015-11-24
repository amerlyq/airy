"{{{1 Apps ============================
if neobundle#tap('vinarise.vim') "{{{
  " detects binary file or large file automatically.
  let g:vinarise_enable_auto_detect=0
  let g:vinarise_detect_large_file_size=0
  " name of command
  let g:vinarise_objdump_command="objdump"
  let g:vinarise_no_default_keymappings=1
  call neobundle#untap()
endif "}}}


"{{{1 Services ============================
if neobundle#tap('vim-xkbswitch') "{{{
  let neobundle#hooks.on_source = '$BUNDLECFGS/on_hooks/xkbswitch.vim'
  call neobundle#untap()
endif "}}}


if neobundle#tap('zeavim.vim') "{{{
  let g:zv_disable_mapping = 1
  nmap <unique> <silent> g?  <Plug>Zeavim
  vmap <unique> <silent> g?  <Plug>ZVVisSelection
  nmap <unique> <silent> [Frame]zd <Plug>ZVKeyDocset
  nmap <unique> <silent> [Frame]zk <Plug>ZVKeyword
  " let g:zv_file_types = {'python' : 'python 3'}
  " let g:zv_docsets_dir = has('unix') ?
  "             \ '~/Important!/docsets_Zeal/' :
  "             \ 'Z:/myUser/Important!/docsets_Zeal/'
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-gnupg') "{{{
  fun! neobundle#hooks.on_post_source(bundle)
    edit  " Re-read buffer to initiate GnuPG autocommands
    " OR:TRY:
    " silent! exe 'doautocmd BufReadCmd' expand('%')
    " silent! exe 'doautocmd FileReadCmd' expand('%')
    " silent! exe 'doautocmd GnuPG BufReadCmd'
  endf
  call neobundle#untap()
endif "}}}


"{{{1 VCS ============================
if neobundle#tap('vim-fugitive')  " Fugitive: {{{1
  autocmd BufReadPost fugitive://* set bufhidden=delete
  nnoremap <silent><unique> [Git]s :Gstatus<CR>
  nnoremap <silent><unique> [Git]l :Glog<CR>
  nnoremap <silent><unique> [Git]d :Gdiff<CR>
  nnoremap <silent><unique> [Git]w :Gwrite<CR>
  nnoremap <silent><unique> [Git]b :Gblame<CR>
  call neobundle#untap()
endif


if neobundle#tap('gitv')  "{{{1
  nnoremap <silent><unique> [Git]v :Gitv! --all<CR>
  xnoremap <silent><unique> [Git]v :Gitv! --all<CR>
  nnoremap <silent><unique> [Git]V :Gitv  --all<CR>
  call neobundle#untap()
endif "}}}
