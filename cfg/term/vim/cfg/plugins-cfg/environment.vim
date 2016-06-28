finish
"{{{1 Path ============================
if neobundle#tap('vim-rooter') "{{{
  let g:rooter_manual_only = 1
  let g:rooter_disable_map = 1
  " let g:rooter_use_lcd = 1
  " Change working directory to that of the current file
  nnoremap <silent><unique> [Frame]cd :Rooter<CR>
  fun! neobundle#hooks.on_post_source(bundle)
    let g:rooter_patterns = g:rooter_patterns + [ '.pjroot', '.agignore' ]
  endf
  call neobundle#untap()
endif
" ALSO:STD:ALWAYS:
  nnoremap <silent><unique> [Frame]cw :lcd %:p:h \| pwd<CR>
  nnoremap <silent><unique> [Frame]cc :lcd ..    \| pwd<CR>
"}}}


if neobundle#tap('vim-altr') "{{{
  nmap <unique> ]f  <Plug>(altr-forward)
  nmap <unique> [f  <Plug>(altr-back)
  command! -bar -nargs=0  A  call altr#forward()
  fun! neobundle#hooks.on_source(bundle)
    " Additional rules
    call altr#define('%/src/%.c', '%/inc/%.h')
  endf
  call neobundle#untap()
else  " OR:STD:
  " Cycle through *.h/*.cpp
  nnoremap <unique> [f :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>
endif "}}}


"{{{1 State ============================
if neobundle#tap('Recover.vim') "{{{
  let g:RecoverPlugin_No_Check_Swapfile = 1
  " XXX: Seems like don't work
  " au MyAutoCmd SwapExists * nested  NeoBundleSource Recover.vim
  call neobundle#untap()
endif "}}}

if neobundle#tap('vim-stay') "{{{
  " set viewoptions=cursor,folds,slash,unix   " Recommended
  call neobundle#untap()
else  " OR:STD:
  " Open at last position
  au MyAutoCmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \|    exe "normal! g'\"" | endif
endif "}}}


" if neobundle#tap('FastFold') "{{{
"   let g:fastfold_fold_movement_commands = [']z', '[z', 'zJ', 'zK']
"   call neobundle#untap()
" else  " OR:STD:
" endif "}}}
