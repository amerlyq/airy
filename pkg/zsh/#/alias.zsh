alias ls='ls -b -CF'
# list all files, with colors
alias la='ls -la'
# long colored list, without dotfiles
alias ll='ls -l'
# long colored list, human readable sizes
alias lh='ls -hAl'
# List files, append qualifier to filenames
alias l='ls -lF'
# Only show dot-directories
alias lad='ls -d .*(/)'
# Only show dot-files
alias lsa='ls -a .*(.)'
# Only files with setgid/setuid/sticky flag
alias lss='ls -l *(s,S,t)'
# Only show symlinks
alias lsl='ls -l *(@)'
# Display only executables
alias lsx='ls -l *(*)'
# Display world-{readable,writable,executable} files
alias lsw='ls -ld *(R,W,X.^ND/)'
# Display the ten biggest files
alias lsbig='ls -flh *(.OL[1,10])'
# Only show directories
alias lsd='ls -d *(/)'
# Only show empty directories
alias lse='ls -d *(/^F)'
# Display the ten newest files
alias lsnew='ls -rtlh *(D.om[1,10])'
# Display the ten oldest files
alias lsold='ls -rtlh *(D.Om[1,10])'
# Display the ten smallest files
alias lssmall='ls -Srl *(.oL[1,10])'
# Display the ten newest directories and ten newest .directories
alias lsnewdir='ls -rthdl *(/om[1,10]) .*(D/om[1,10])'
# Display the ten oldest directories and ten oldest .directories
alias lsolddir='ls -rthdl *(/Om[1,10]) .*(D/Om[1,10])'
