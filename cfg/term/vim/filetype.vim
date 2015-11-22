if exists("did_load_filetypes") | finish | endif

augroup filetypedetect
  " Langs
  au BufRead,BufNewFile *.scala   setf scala
  au BufRead,BufNewfile *.n       setf nemerle
  au BufRead,BufNewfile *.p5      setf perl
  au BufRead,BufNewfile *.p6      setf perl6
  au BufRead,BufNewFile *.tex.erb setf tex.eruby
  " Asm
  au BufRead,BufNewFile *.asm  setl ft=masm syntax=masm
  au BufRead,BufNewFile *.inc  setl ft=masm syntax=masm
  au BufRead,BufNewFile *.[sS] setl ft=gas syntax=gas
  au BufRead,BufNewFile *.hla  setl ft=hla syntax=hla
  " Configuration
  au BufRead,BufNewFile {Gemfile,Rakefile,Thorfile,Vagrantfile}
        \ setl ft=ruby fdm=syntax fdn=1
  " System
  au BufRead,BufNewFile {*.log*,log-*}       setf messages
  au BufRead,BufNewFile {PKGBUILD,.AURINFO}  setf sh
  au BufRead,BufNewFile {*.automount,*.mount,*.path,*.socket,*.swap} setf systemd
augroup END

" Use Zeal on Linux for context help
" au FileType {ansible,go,python,php,css,less,html,markdown}
"     \ nnoremap <silent><buffer> K :!zeal --query "<C-R>=&ft<CR>:<cword>"&<CR><CR>
" au FileType {javascript,sql,ruby,conf,sh}
"     \ nnoremap <silent><buffer> K :!zeal --query "<cword>"&<CR><CR>
