" To  compile micro-programs really fast
" vim:ts=2:sw=2:sts=2

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
noremap <silent> <Leader>j <Esc>:<C-U>w \| CompilerInDir 'Silent'<CR>

" Launch executable scripts
noremap <Leader>K :<C-U>!./%<CR>
noremap <Leader>k :<C-U>!!<CR>

