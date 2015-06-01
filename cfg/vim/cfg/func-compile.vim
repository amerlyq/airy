" To  compile micro-programs really fast
" vim:ts=2:sw=2:sts=2

function! CompileInDir(...)
  let run = a:0 >= 1  ?  a:1 . ' '  :  '!'
  " 'actualee ' . @% . ' || ' .
  exec l:run . 'abyss || { [ $? -eq 255 ] && abyss ' . @% . '}'
  " set makeprg=ruby\ -c\ %
endfunction

command! -bar -nargs=? CompilerInDir call CompileInDir(<args>)
" \| cw
noremap <silent> <unique> <F5> <Esc>:<C-U>w \| CompilerInDir<CR>
noremap <silent> <unique> <C-J> <Esc>:<C-U>w \| CompilerInDir 'Silent'<CR>
noremap <silent> <unique> <Leader>m <Esc>:<C-U>w \| Silent abyss<CR>
noremap <silent> <unique> <Leader>j <Esc>:<C-U>w \| Silent actualee %<CR>
noremap <silent> <unique> <Leader>M <Esc>:<C-U>w \| Make<CR>

" map <F9> :!gcc -o %< % <enter><CR><C-w>

" Launch command line fast (preliminary executable scripts)
let g:run_cmdline = ""
function! s:RunCmdLine(bChange)
  if empty(g:run_cmdline)
    let g:run_cmdline = "!./" . getreg('%')
    echo g:run_cmdline
  endif
  if a:bChange
    let g:run_cmdline = getreg(':')
    echo g:run_cmdline | return
  endif
  exec g:run_cmdline
endfunction

" Shortcuts to <launch setted|change by ':'> command
noremap <unique> <Leader>k :<C-U>call <SID>RunCmdLine(0)<CR>
noremap <unique> <Leader>K :<C-U>call <SID>RunCmdLine(1)<CR>

