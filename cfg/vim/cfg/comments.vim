if !has("autocmd") | finish | endif

augroup FTOptions "{{{2
    autocmd!
    au FileType c,cpp,cs,java          setlocal commentstring=//\ %s
    au FileType xdefaults              setlocal commentstring=!\ %s
    au FileType votl                   setlocal commentstring=:\ %s
augroup END "}}}2


" Open at last position
autocmd BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
    \| exe "normal g'\"" | endif

autocmd BufRead,BufNewFile
    \ {Gemfile,Rakefile,Thorfile,Vagrantfile} set ft=ruby

" json syntax highlighting: deprecated. There are json-plugins
"autocmd BufNewFile,BufRead *.json set ft=javascript

