" To  compile micro-programs really fast
" vim:ts=2:sw=2:sts=2

function! CompileInDir(...)
  let run = a:0 >= 1  ?  a:1 . ' '  :  '!'
  " 'actualee ' . @% . ' || ' .
  exec l:run . 'abyss -a || { (($?==10)) && abyss -f '.shellescape(@%).'; }'
  " set makeprg=ruby\ -c\ %
endfunction

com! -nargs=1 Silent | exe ':silent !'.<q-args> | exe ':redraw!'
command! -bar -nargs=? CompilerInDir call CompileInDir(<args>)
" \| cw
noremap <unique><silent> <F5> <Esc>:<C-U>up \| CompilerInDir<CR>
" DISABLED: with LatchCtrl C-j has detrimental effects in message.log.*
" noremap <unique><silent> <C-J> <Esc>:<C-U>up \| CompilerInDir 'Silent'<CR>

com! -bar -bang -nargs=* Abyss let s:mp=&mp
    \|set mp=abyss|try|exe 'Make<bang> <args>'|cat|final|let &mp=s:mp|endt
noremap <unique><silent> <Leader>m <Esc>:<C-U>up \| Abyss -r \| cw<CR>
noremap <unique><silent> <Leader>M <Esc>:<C-U>up \| Abyss!<CR>
noremap <unique><silent> [Unite]<Leader>m <Esc>:Copen<CR>

noremap <unique><silent> <Leader>j <Esc>:<C-U>up \| Silent actualee %<CR>

" map <F9> :!gcc -o %< % <enter><CR><C-w>

" Launch command line fast (preliminary executable scripts)
let g:run_cmdline = ""
function! s:RunCmdLine(bChange)
  if empty(g:run_cmdline)
    let g:run_cmdline = '!' . expand('%:p')
    echo g:run_cmdline
  endif
  if a:bChange
    let g:run_cmdline = getcmdline()  " getreg(':')
    echo g:run_cmdline | return g:run_cmdline
  endif
  " let pos = getcmdpos()
  exec g:run_cmdline
  " call setcmdpos(pos)
  " return g:run_cmdline
endfunction

" Shortcuts to <launch setted|change by ':'> command
nnoremap <unique> <Leader>k :<C-U>call <SID>RunCmdLine(0)<CR>
nnoremap <unique> <Leader>K :<C-U>call <SID>RunCmdLine(1)<CR>
nnoremap <unique> <Leader><C-k> :<C-U>!$PWD/%<Space>
cnoremap <unique>    <C-s>  <C-\>e<SID>RunCmdLine(1)<CR>
