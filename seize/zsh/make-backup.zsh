# make a backup of a file
bk() {
    cp -a "$1" "${1}_$(date --iso-8601=seconds)"
}
