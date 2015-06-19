if !has("autocmd") | finish | endif


augroup StartupOptions
    autocmd!
    " Open at last position
    au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$")
        \| exe "normal g'\"" | endif

    au BufRead,BufNewFile *.vim setlocal ts=2 sw=2 sts=2 fdm=marker fdl=1
augroup END


augroup AdditionalFiletypes "{{{2
    autocmd!
    au BufRead,BufNewFile {PKGBUILD,.AURINFO} setfiletype PKGBUILD
    au BufRead,BufNewFile
        \ {Gemfile,Rakefile,Thorfile,Vagrantfile} set ft=ruby
    au BufRead,BufNewFile
        \ {*tmux.conf*,Tmuxfile,*tmux/config} set ft=tmux
    au BufRead,BufNewFile
        \ {*.automount,*.mount,*.path,*.service,*.socket,*.swap,*.target,*.timer}
        \ set ft=systemd
augroup END


augroup CommentOptions "{{{2
    autocmd!
    au FileType c,cpp,cs,java          setlocal commentstring=//\ %s
    au FileType xdefaults              setlocal commentstring=!\ %s
    au FileType votl                   setlocal commentstring=:\ %s
augroup END "}}}2


" json syntax highlighting: deprecated. There are json-plugins
"autocmd BufNewFile,BufRead *.json set ft=javascript
