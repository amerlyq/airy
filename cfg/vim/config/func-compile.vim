" To  compile micro-programs really fast

function! CompileInDir(...)
  let run = a:0 >= 1  ?  a:1 . ' '  :  '!'

  exec l:run . 'abyss || abyss ' . @%
  " set makeprg=ruby\ -c\ %
  "   let lst=substitute(glob(dir.'/**/*.c'), '\n', ' ', 'g')
endfunction

command! -bar -nargs=? CompilerInDir call CompileInDir(<args>)
" \| cw
noremap <silent> <F5> <Esc>:<C-U>w \| CompilerInDir<CR>
noremap <silent> <C-J> <Esc>:<C-U>w \| CompilerInDir 'Silent'<CR>

" vim:ts=2:sw=2:sts=2
