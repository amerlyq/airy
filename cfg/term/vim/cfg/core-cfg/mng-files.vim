" Workflow manipulation
" http://vim.wikia.com/wiki/Mapping_keys_in_Vim_-_Tutorial_%28Part_3%29

" Save, Drop, File
" ATTENTION be aware, that :update will not create NEW files like touch!
noremap <Leader>s :<C-U>update<CR>
" noremap <Leader>S :<C-U>wa<CR>
noremap <Leader>d :<C-U>q<CR>
noremap <Leader>D :<C-U>qa<CR>
" cnoremap <Leader>d <C-E><C-U>q<CR>
" SAVE: {koi8-r, imb866, cp-1251, utf8, reg:utf-16le, :set fenc=utf8}
noremap <Leader>S :<C-U>write ++enc=utf8<CR>
noremap <Leader><C-S> :saveas<Space>


"" Change current path
nnoremap <silent><unique> [Frame]cw :lcd %:p:h \| pwd<CR>
nnoremap <silent><unique> [Frame]cc :lcd ..    \| pwd<CR>


" Cycle through *.h/*.cpp
nnoremap <unique> [f :e %:p:s,.h$,.X123X,:s,.cpp$,.h,:s,.X123X$,.cpp,<CR>


" STD: Open at last position (instead of vim-stay)
"   au MyAutoCmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
"       \|    exe "normal! g'\"" | endif


" BUG can't work in vim w/o redirections?
" if executable('r.shell')
"   set shell=r.shell
"   set shellcmdflag=
" elseif exists('$SHELL')
  " WARNING Don't use '-i':  'stty: standard input: Inappropriate ioctl for device'
  set shell=$SHELL
" endif

" if has('nvim')
"   " noremap <silent> <Leader>Z :<C-u>edit <C-r>=&errorfile<CR><CR>
"   noremap <silent> <Leader>Z :<C-u>term<CR>
" else
"   " Go to by ':sh' or mapping ',z'.  DFL: /bin/sh
"   " Go inside shell to see output of commands like ':! ..'. Return on <C-d>
"   noremap <silent> <Leader>Z :<C-u>shell<CR>
" endif
" command! -bar -nargs=+ Z  exe '!zsh -c "source ~/.shell/aliases; eval '.<q-args>.'"'
" command! -bar -nargs=+ Z call RedirectOutput('!zsh -c "source ~/.shell/aliases; eval '.<q-args>.'"')
" nnoremap <unique> <Leader>z  :Z<Space>
" vnoremap <unique> <Leader>z  :!
" set shell=$SHELL\ -c\ source\ ~/.shell/aliases\ \&\&\ eval\ "ls"


" Close current buffer while retaining window
function! s:BufDelSafe()
  if bufnr('%') == bufnr('$')
    exec 'bprev|bdelete ' . bufnr('%')
  else
    exec 'bnext|bdelete ' . bufnr('%')
  endif
endfunction
command! -bar Safebd call <SID>BufDelSafe()
nnoremap <Leader>x :<C-U>Safebd<CR>

" reload current buffer while discarding changes
"nnoremap <Leader>e :edit!<cr>
