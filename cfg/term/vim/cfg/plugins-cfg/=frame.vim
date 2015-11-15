" USE let &commentstring=' "%s'

if neobundle#tap('DrawIt') "{{{
  map <unique> [Frame]DI  <Plug>DrawItStart
  map <unique> [Frame]DS  <Plug>DrawItStop
  map <unique> [Frame]Dsw <Plug>SaveWinPosn
  map <unique> [Frame]Drw <Plug>RestoreWinPosn
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-rooter') "{{{
  let g:rooter_manual_only = 1
  let g:rooter_disable_map = 1
  " Change working directory to that of the current file
  nnoremap <unique><silent> [Frame]cw :lcd %:p:h \| pwd<CR>
  nnoremap <unique><silent> [Frame]cd :Rooter<CR>
  call neobundle#untap()
endif "}}}


if neobundle#tap('linediff.vim') "{{{
  nnoremap <unique> [Frame]L  :LinediffReset<CR>
  vnoremap <unique> [Frame]L  :Linediff<CR>
  call neobundle#untap()
endif "}}}


if neobundle#tap('zeavim.vim') "{{{
  let g:zv_disable_mapping = 1
  nmap <unique> <silent> [Frame]z  <Plug>Zeavim
  vmap <unique> <silent> [Frame]z  <Plug>ZVVisSelection
  nmap <unique> <silent> [Frame]Zd <Plug>ZVKeyDocset
  nmap <unique> <silent> [Frame]Zk <Plug>ZVKeyword
  " let g:zv_file_types = {'python' : 'python 3'}
  " let g:zv_docsets_dir = has('unix') ?
  "             \ '~/Important!/docsets_Zeal/' :
  "             \ 'Z:/myUser/Important!/docsets_Zeal/'
  call neobundle#untap()
endif "}}}


if neobundle#tap('NrrwRgn') "{{{
":: Focus on content in split window
  " Create two region buffers and use :diffthis --> instead of LineDiff
  " Multiselection in new buffer! :v/^#/NRP | NRM
  " Tip -- completely delete blocks you don't want to change.
  " let g:nrrw_rgn_nohl = 1
  " split buffer in same window
  let g:nrrw_topbot_leftright = 'botright'
  nmap <unique> <Leader>n <Plug>NrrwrgnDo
  xmap <unique> <Leader>n <Plug>NrrwrgnDo
  omap <unique> <Leader>n <Plug>NrrwrgnDo
  " separate buffer
  nmap <unique> <Leader>N <Plug>NrrwrgnBangDo
  xmap <unique> <Leader>N <Plug>NrrwrgnBangDo
  omap <unique> <Leader>N <Plug>NrrwrgnBangDo
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-altr') "{{{
":: Toggle between alternative files (.h, .cpp, ...)
  nmap <unique> ]f  <Plug>(altr-forward)
  nmap <unique> [f  <Plug>(altr-back)
  " ALT map <F4> :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>
  command! A  call altr#forward()
  " Additional rules
  fun! neobundle#hooks.on_source(bundle)
    call altr#define('%/src/%.c', '%/inc/%.h')
  endf
  call neobundle#untap()
endif "}}}


if neobundle#tap('vim-signature') "{{{
  let g:SignatureIncludeMarkers = '!@#$%^&*()[]".'
  let g:SignaturePurgeConfirmation = 1
  let g:SignaturePrioritizeMarks = 0
  call neobundle#untap()
endif "}}}
