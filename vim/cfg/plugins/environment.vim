""" Env {{{1

"" HACK Adds support of FocusIn/Out events for terminal vim {{{1
" ATTENTION: neovim has broken t_ti
call dein#add('amerlyq/vim-focus-autocmd', {'if': '!has("nvim")'})

call dein#add('embear/vim-localvimrc', {'lazy': 0,
  \ 'on_cmd': 'LocalVimRC',
  \ 'hook_add': "
\\n   let g:localvimrc_name = [ '.lvimrc' ]
\\n   let g:localvimrc_sandbox = 1
\\n   let g:localvimrc_persistent = 1
\\n   let g:localvimrc_persistence_file = $VPLUGS.'/localvimrc_persistent'
\"})


""" Path {{{1

"" Change root working dir of curr file by auto/manual-cd in the repo {{{1
" EXPL:(lazy) Only if you want for auto-cd to work
" CHG: \ 'on_map': '<Leader>cd',
call dein#add('airblade/vim-rooter', {
  \ 'on_cmd': 'Rooter',
  \ 'hook_post_source': "
\\n   let g:rooter_patterns += ['.pjroot', '.agignore']
\", 'hook_source': "
\\n   let g:rooter_manual_only = 1
\\n   let g:rooter_disable_map = 1
\\n   \" let g:rooter_use_lcd = 1
\", 'hook_add': "
\\n   nnoremap <silent><unique> [Frame]cd :Rooter<CR>
\"})


"" Extract the selection into a new file with same extension
" ALT: https://github.com/lucerion/vim-extract
" USAGE: :Xtract newfilename<CR>
" FIXME: move from fork to 'rstacruz' when fixed trailing dot
call dein#add('specious/vim-xtract', {
  \ 'on_cmd': 'Xtract'})



"" Switch between alternative files [c,cpp,cxx,cc] <-> [h,hpp] {{{1
" EXPL:(no <unique>) overrides my STD 'cycle through'
call dein#add('kana/vim-altr', {
  \ 'on_func': 'altr#',
  \ 'on_map': [['nvoic', '<Plug>']],
  \ 'hook_source': "
\\n   call altr#define('%/src/%.c', '%/inc/%.h')
\\n   call altr#define('%/src/%.cpp', '%/inc/%.h', '%/t/%_test.cpp')
\", 'hook_add': "
\\n   nmap <unique> ]f  <Plug>(altr-forward)
\\n   nmap <unique> [f  <Plug>(altr-back)
\\n   command! -bar -nargs=0  A  call altr#forward()
\"})



"" Opens at pos file:line:col, file(line:col), file::method {{{1
" EXPL:(non-lazy) watch over Buf*au for :e, :edit to work as expected
" \ 'on_map': [[nx, gF]]
call dein#add('kopischke/vim-fetch')



""" State {{{1

" CHECK:(test on_event) HACK commands Recoverer{Diff,End,Remove}
" DEPRECATED:
"   chrisbra/Recover.vim (can't fetch neovim recovery messages)
call dein#add('amerlyq/recoverer.vim')
" TRY:FIX:(lazy) double loading => excessive tab
"   \ 'on_func': 'recoverer#',
"   \ 'on_event': 'SwapExists'

" OR:STD: (R)ecover -- then ':DiffOrig', and after comparing -- ':update'



"" Session [folds,cursor,etc] auto save/restore {{{1
" Works with buffer edit, argdo, bufdo, etc
" EXPL:(non-lazy) always watch over Buf*au for save/restore state
" \ 'on_cmd': ['CleanViewdir', 'StayReload']
" ALT: tpope/vim-obsession
call dein#add('kopischke/vim-stay', {'lazy': 0,
  \ 'hook_add': "
\\n   augroup stay_no_lcd
\\n     autocmd!
\\n     autocmd User BufStaySavePre  if haslocaldir() | let w:lcd = getcwd() | cd - | cd - | endif
\\n     autocmd User BufStaySavePost if exists('w:lcd') | execute 'lcd' fnameescape(w:lcd) | unlet w:lcd | endif
\\n   augroup END
\"})
" HACK:(stay_no_lcd): prevent :lcd from saving into view
"   https://github.com/kopischke/vim-stay/issues/11
" set viewoptions=cursor,folds,slash,unix   " Recommended



"" Converts automatic folds into manual to reduce recomputation CPU load {{{1
" BUG:FIXME: slow in NORMAL on *.c files > 8000 lines
"   # THINK: use only on-demand or filetype?
"   let g:fastfold_fold_movement_commands = [']z', '[z', 'zJ', 'zK']
" Konfekt/FastFold:
"       DEPRECATED: Konfekt/FoldText:
"   # \ 'on_map': [[n, zuz, zx, zX, za, zA, zo, zO, zc, zC], ']z', '[z', zJ, zK]
"   # \ 'on_cmd': FastFoldUpdate
"   lazy: 0  # EXPL: always converts in all buffers.
" on_event = 'BufEnter'
" hook_post_source = 'FastFoldUpdate'



"" Buffer to view references with history {{{1
" TRY:DEV: integrate my vim-dict into this to get viewer+history
" repo = 'thinca/vim-ref'
" on_map = {n = '<Plug>'}
" hook_source = 'source ~/.vim/rc/plugins/ref.rc.vim'
