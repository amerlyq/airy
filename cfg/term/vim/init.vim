let $VIMHOME=expand('~/.vim')
let $CACHE=expand('~/.cache/vim')

source $VIMHOME/neobundle.vim

let mapleader=","
runtime! bundle/*.vim cfg/*.vim ext/*.vim
