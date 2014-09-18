" To fast compile micro-programs

function! CompileInDir()
  let dir=substitute(getcwd(), '/\(src\|inc\)$', '', '')
  let name=fnamemodify(l:dir, ":t") . '.bin'
  let bdir=l:dir . '/build'
  call mkdir(l:dir, 'p')
  if filereadable(l:dir . 'Makefile')
    exec 'make -C' . l:bdir
  " set makeprg=ruby\ -c\ %
  elseif filereadable(l:dir . 'compile')
    exec '!cd ' . l:dir . ' && ./compile && cd ' . l:bdir . ' && ./' . l:name
  else
    let lst=substitute(glob(dir.'/**/*.c'), '\n', ' ', 'g')
    exec '!cd ' . l:bdir . '&& gcc -O0 -g -o ' . l:name .
          \ ' -I ' . l:dir . ' ' . l:lst '&& ./' . l:name
  endif
endfunction

command! -bar CompilerInDir call CompileInDir()
noremap <silent> <F5> <Esc>:<C-U>w \| CompilerInDir \| cw<CR>
noremap <silent> <C-J> <Esc>:<C-U>w \| CompilerInDir \| cw<CR>
" vim:ts=2:sw=2:sts=2
