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


if neobundle#tap('vinarise.vim') "{{{
  " detects binary file or large file automatically.
  let g:vinarise_enable_auto_detect=0
  let g:vinarise_detect_large_file_size=0
  " name of command
  let g:vinarise_objdump_command="objdump"
  let g:vinarise_no_default_keymappings=1
  call neobundle#untap()
endif "}}}
