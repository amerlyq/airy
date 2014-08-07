# cd to directoy and list files
cl() {
    emulate -L zsh
    cd $1 && ls -a
}
