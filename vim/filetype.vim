" if exists("did_load_filetypes") | finish | endif
" if exists('s:custom_filetypes')|finish|else|let s:custom_filetypes=1|endif

augroup custom_filetypes
  autocmd!
  " Langs
  au BufRead,BufNewFile *.scala   setf scala
  au BufRead,BufNewfile *.n       setf nemerle
  au BufRead,BufNewfile *.p5      setf perl
  au BufRead,BufNewfile *.p6      setf perl6
  au BufRead,BufNewFile *.tex.erb setf tex.eruby
  " Asm
  au BufRead,BufNewFile *.asm  setl ft=masm syntax=masm
  au BufRead,BufNewFile *.inc  setl ft=masm syntax=masm
  au BufRead,BufNewFile *.s    setl ft=nasm syntax=nasm
  au BufRead,BufNewFile *.S    setl ft=gas syntax=gas
  au BufRead,BufNewFile *.hla  setl ft=hla syntax=hla
  " Configuration
  au BufRead,BufNewFile {Gemfile,Gemfile.lock,Rakefile,Thorfile,Vagrantfile}  setl ft=ruby fdm=syntax fdn=1
  au BufRead,BufNewFile *.reg   edit ++enc=utf16le
  au BufRead,BufNewFile *.pc    setf automake
  au BufRead,BufNewFile {Config.in,Kconfig}    setf kconfig  " Buildroot,BusyBox
  au BufRead,BufNewFile {*.config,*.frag,*_defconfig,defconfig}  setf make     " Buildroot,Linux
  " -- override default runtime mistake 'ft=hog'
  au BufRead,BufNewFile *.rules setl ft=udevrules

  " MOVE: ftdetect/xtref.vim -- detection must be part of xtref plugin
  au BufRead,BufNewFile *.otl   setl noet  " TEMP:REM*

  " System
  au BufRead,BufNewFile {*.gpg,*.asc}   setf gpg
  au BufRead,BufNewFile *.log*          setf messages
  au BufRead,BufNewFile {PKGBUILD,.AURINFO,*.pkgbuild}  setf sh
  au BufRead,BufNewFile {*.automount,*.mount,*.path,*.socket,*.swap,*.target,*.service} setf systemd
  au BufRead ~/sdk/*                    setl ts=8
  au BufRead ~/.purple/logs/*           setf pidgin
  au BufRead ~/.{mail,config/mutt/messages}/*   setf mail
  au BufRead /tmp/gdb/{log.cfg,*/*.cfg} setl ft=fasm ts=8 nowrap
  au BufRead gdb-log.cfg                setl ft=fasm ts=8 nowrap
  au BufRead,BufNewFile *.ftrace        setl ft=ftrace
  au BufRead,BufNewFile {*.weechatlog,/@/chat/weechat/*.txt}  setl ft=weechatlog
augroup END

" Use Zeal on Linux for context help
" au FileType {ansible,go,python,php,css,less,html,markdown}
"     \ nnoremap <silent><buffer> K :!zeal --query "<C-R>=&ft<CR>:<cword>"&<CR><CR>
" au FileType {javascript,sql,ruby,conf,sh}
"     \ nnoremap <silent><buffer> K :!zeal --query "<cword>"&<CR><CR>
