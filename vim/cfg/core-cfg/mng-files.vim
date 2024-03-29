" Workflow manipulation
" http://vim.wikia.com/wiki/Mapping_keys_in_Vim_-_Tutorial_%28Part_3%29

"" Appoint a line feed.
" ALT: :set fenc=utf8
" enc: [koi8-r, imb866, cp1251, cp866, utf8, reg:utf-16le, ucs-2le, ucs-2]
" ff: [unix, dos, mac]
com! -bang -bar -complete=file -nargs=? Wunix
  \| set nobomb
  \| write<bang> ++enc=utf8 ++ff=unix ++nobin <args>
  \| edit <args>
com! -bang -bar -complete=file -nargs=? Ewin
  \ edit<bang> ++enc=cp1251 ++ff=dos ++nobin <args>

" FIXED:(E173):SEE http://vim.1045645.n5.nabble.com/Re-how-to-suppress-quot-E173-1-more-file-to-edit-quot-td5716336.html#a5716344
" ALT: if argc()>1|sil blast|sil bfirst|en
set noconfirm   " abort action on unsaved for Qfast to work
com! -bar Qfast try|sil quit|catch/:E37/|conf quit
  \|catch/:E173/|try|sil qall|catch/E37/|conf qall|endt|endt

" Save, Drop, File
" ATTENTION be aware, that :update will not create NEW files like touch!
noremap <Leader>s :<C-U>update<CR>
noremap <Leader>ы :<C-U>update<CR>
" noremap <Leader>S :<C-U>wa<CR>
noremap <Leader>d :<C-U>Qfast<CR>
noremap <Leader>в :<C-U>Qfast<CR>
noremap <Leader>D :<C-U>qa<CR>
" cnoremap <Leader>d <C-E><C-U>q<CR>
noremap <Leader>S :<C-U>Wunix<CR>
noremap <Leader><C-S> :saveas<Space>


"" Change current path
nnoremap <silent><unique> [Frame]cD :exe 'lcd '.fnameescape(get(systemlist('git rev-parse --show-superproject-working-tree'),0,'.'))<CR>
nnoremap <silent><unique> [Frame]cw :lcd %:p:h<CR>
nnoremap <silent><unique> [Frame]cc :lcd ..<CR>
nnoremap <silent><unique> [Frame]ct :exe 'lcd '.fnameescape(<SID>tagdir())<CR>

fun! s:tagdir()
  let d = get(tagfiles(), 0)
  if l:d
    let d = fnamemodify(d, ':p:h')
  else
    let d = fnamemodify(getcwd(), ':p')
    wh !filereadable(d.'/tags')
      if d=='/'| throw "tag not found" |en
      let d = fnamemodify(d, ':h')
    endw
  endif
  return l:d
endf



" STD: Open at last position (instead of vim-stay)
"   au MyAutoCmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
"       \|    exe "normal! g'\"" | endif


" BUG can't work in vim w/o redirections?
" if executable('r.sh')
"   set shell=r.sh
"   set shellcmdflag=
" elseif exists('$SHELL')
  " WARNING Don't use '-i':  'stty: standard input: Inappropriate ioctl for device'
  " DISABLED: inherits "r.sh" from ranger which accesses too much files
  " set shell=$SHELL
  set shell=/bin/sh
" endif

" if has('nvim')
"   " noremap <silent> <Leader>Z :<C-u>edit <C-r>=&errorfile<CR><CR>
"   noremap <silent> <Leader>Z :<C-u>term<CR>
" else
"   " Go to by ':sh' or mapping ',z'.  DFL: /bin/sh
"   " Go inside shell to see output of commands like ':! ..'. Return on <C-d>
"   noremap <silent> <Leader>Z :<C-u>shell<CR>
" endif

" command! -bar -nargs=+ Z  exe '!r.sh -c <q-args>'
" command! -bar -nargs=+ Z call RedirectOutput('!r.sh -c <q-args>')
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
nnoremap <Leader>ч :<C-U>Safebd<CR>

" reload current buffer while discarding changes
"nnoremap <Leader>e :edit!<cr>
