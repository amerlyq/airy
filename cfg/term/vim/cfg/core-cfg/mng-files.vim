" Workflow manipulation
" http://vim.wikia.com/wiki/Mapping_keys_in_Vim_-_Tutorial_%28Part_3%29

" Save, Drop, File
noremap <Leader>s :<C-U>update<CR>
" noremap <Leader>S :<C-U>wa<CR>
noremap <Leader>d :<C-U>q<CR>
noremap <Leader>D :<C-U>qa<CR>
" cnoremap <Leader>d <C-E><C-U>q<CR>
" SAVE: {koi8-r, imb866, cp-1251, utf8, reg:utf-16le, :set fenc=utf8}
noremap <Leader>S :<C-U>write ++enc=utf8<CR>
noremap <Leader><C-S> :saveas<Space>


if has('unix')
  noremap <Leader>f :<C-U>RangerChooser<CR>
elseif has('win32') || has('win64')
  noremap <Leader>f :<C-U>VimFiler<CR>
  let $SHELL='cmd.exe'  " Is any sense using git-msys under git instead?
endif

" BUG can't work in vim w/o redirections?
" if executable('r.shell')
"   set shell=r.shell
"   set shellcmdflag=
" elseif exists('$SHELL')
  " WARNING Don't use '-i':  'stty: standard input: Inappropriate ioctl for device'
  set shell=$SHELL
" endif

if has('nvim')
  noremap <silent> <Leader>Z :<C-u>edit <C-r>=&errorfile<CR><CR>
  " noremap <silent> <Leader>Z :<C-u>term<CR>
else
  " Go to by ':sh' or mapping ',z'.  DFL: /bin/sh
  " Go inside shell to see output of commands like ':! ..'. Return on <C-d>
  noremap <silent> <Leader>Z :<C-u>shell<CR>
endif
command! -bar -nargs=+ Z  exe '!zsh -c "source ~/.shell/aliases; eval '.<q-args>.'"'
" command! -bar -nargs=+ Z call RedirectOutput('!zsh -c "source ~/.shell/aliases; eval '.<q-args>.'"')
nnoremap <unique> <Leader>z  :Z<Space>
vnoremap <unique> <Leader>z  :!
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

" DEV TRY redirect any vim command (like g] for tags) into new buffer to search
"   ALT redirect into quickfix list
fun! RedirectOutput(...)
  redir @z
  silent exe join(a:000, ' ')
  redir END
  new | put z
endf
command! -bar -nargs=+ R call RedirectOutput(<q-args>)
