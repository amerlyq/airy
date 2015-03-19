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
noremap <silent> <F5> <Esc>:<C-U>w \| CompilerInDir<CR>
noremap <silent> <C-J> <Esc>:<C-U>w \| CompilerInDir 'Silent'<CR>
noremap <silent> <Leader>m <Esc>:<C-U>w \| Silent abyss<CR>
noremap <silent> <Leader>j <Esc>:<C-U>w \| Silent actualee %<CR>

" Launch executable scripts
noremap <Leader>k :<C-U>!./%<CR>
noremap <Leader>K :<C-U>!!<CR>

