alias -s {avi,mpeg,mpg,mov,mkv}=mpv

alias esync='sudo eix-sync'
alias fetch='sudo emerge --update --deep --newuse --fetchonly @world'
alias update='sudo emerge --update --deep --newuse @world'
alias emerge='sudo emerge'
alias vimu='sudo vim /etc/portage/package.use'
alias gvimu='sudo gvim /etc/portage/package.use'
alias s2disk='sudo hibernate'
alias s2ram='sudo hibernate-ram'
alias halt='sudo shutdown -h now'
alias reboot='sudo shutdown -r now'
alias man='nocorrect man'
alias mv='nocorrect mv'
alias mkdir='nocorrect mkdir'
alias sudo='nocorrect sudo'


alias ls='ls --color=auto -b -CF'
# list all files, with colors
alias la='ls -la --color=auto'
# long colored list, without dotfiles
alias ll='ls -l --color=auto'
# long colored list, human readable sizes
alias lh='ls -hAl --color=auto'
# List files, append qualifier to filenames
alias l='ls -lF --color=auto'
# Only show dot-directories
alias lad='ls -d .*(/) --color=auto'
# Only show dot-files
alias lsa='ls -a .*(.) --color=auto'
# Only files with setgid/setuid/sticky flag
alias lss='ls -l *(s,S,t) --color=auto'
# Only show symlinks
alias lsl='ls -l *(@) --color=auto'
# Display only executables
alias lsx='ls -l *(*) --color=auto'
# Display world-{readable,writable,executable} files
alias lsw='ls -ld *(R,W,X.^ND/) --color=auto'
# Display the ten biggest files
alias lsbig='ls -flh *(.OL[1,10]) --color=auto'
# Only show directories
alias lsd='ls -d *(/) --color=auto'
# Only show empty directories
alias lse='ls -d *(/^F) --color=auto'
# Display the ten newest files
alias lsnew='ls -rtlh *(D.om[1,10]) --color=auto'
# Display the ten oldest files
alias lsold='ls -rtlh *(D.Om[1,10]) --color=auto'
# Display the ten smallest files
alias lssmall='ls -Srl *(.oL[1,10]) --color=auto'
# Display the ten newest directories and ten newest .directories
alias lsnewdir='ls -rthdl *(/om[1,10]) .*(D/om[1,10]) --color=auto'
# Display the ten oldest directories and ten oldest .directories
alias lsolddir='ls -rthdl *(/Om[1,10]) .*(D/Om[1,10]) --color=auto'

# Remove current empty directory. Execute \kbd{cd ..; rmdir $OLDCWD}
alias rmcdir='cd ..; rmdir $OLDPWD || cd $OLDPWD'

alias grep='grep --color=auto'
alias vdir='vdir --color=auto'

alias da='du -sch'

alias -g C='|wc -l'
alias -g G='|grep'
alias -g H='|head'
alias -g L='|less'
alias -g LL='|& less -r'
alias -g N='&>/dev/null'
alias -g T='|tail'
