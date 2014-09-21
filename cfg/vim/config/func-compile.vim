" To fast compile micro-programs

function! CompileInDir(...)
  let run = a:0 >= 1  ?  a:1 . ' '  :  '!'

  let dir=substitute(getcwd(), '/\(src\|inc\)$', '', '')
  let name=fnamemodify(l:dir, ":t") . '.bin'
  let bdir=l:dir . '/build'
  if filereadable(l:dir . '/CMakeLists.txt')
    exec '!sir bR'
  elseif filereadable(l:dir . '/Makefile')
    exec 'make -C' . l:bdir
    " set makeprg=ruby\ -c\ %
  elseif filereadable(l:dir . '/compile')
    exec l:run . 'cd ' . l:dir . ' && ./compile'
  else
    let lst=substitute(glob(dir.'/**/*.c'), '\n', ' ', 'g')
    if len(l:lst) > 0
      call mkdir(l:bdir, 'p')
      exec l:run . 'cd ' . l:bdir . ' && gcc -O0 -g -o ' . l:name .
          \ ' -I ' . l:dir . ' ' . l:lst ' && ./' . l:name
    endif
  endif
  if filereadable(l:dir . '/run')
    exec l:run . 'cd ' . l:dir . ' && ./run'
  endif
endfunction

command! -bar -nargs=? CompilerInDir call CompileInDir(<args>)
" \| cw
noremap <silent> <F5> <Esc>:<C-U>w \| CompilerInDir<CR>
noremap <silent> <C-J> <Esc>:<C-U>w \| CompilerInDir 'Silent'<CR>

" vim:ts=2:sw=2:sts=2
