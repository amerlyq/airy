" Workflow manipulation
" http://vim.wikia.com/wiki/Mapping_keys_in_Vim_-_Tutorial_%28Part_3%29

" SAVE: {koi8-r, imb866, cp-1251, utf8, reg:utf-16le, :set fenc=utf8}
noremap <Leader>S :<C-U>write ++enc=utf8<CR>
noremap <Leader><C-S> :saveas<Space>

" Ag, Save, Drop, File,
noremap <Leader>s :<C-U>w<CR>
" noremap <Leader>S :<C-U>wa<CR>
noremap <Leader>d :<C-U>q<CR>
noremap <Leader>D :<C-U>qa<CR>
" cnoremap <Leader>d <C-E><C-U>q<CR>

if has('unix')
  noremap <Leader>f :<C-U>RangerChooser<CR>
elseif has('win32') || has('win64')
  noremap <Leader>f :<C-U>VimFiler<CR>
  let $SHELL='cmd.exe'  " Is any sense using git-msys under git instead?
endif

" Go inside shell to see output of commands like ':! ..'. Return on <C-d>
set shell=$SHELL  "go to by ':sh' or mapping ',z'.  Def: /bin/sh
if has('nvim')
  noremap <silent> <Leader>z :<C-u>edit <C-r>=&errorfile<CR><CR>
else
  noremap <silent> <Leader>z :<C-u>shell<CR>
endif


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
