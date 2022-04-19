let $VIMHOME=fnamemodify(resolve(expand('<sfile>')), ':h')

let g:indent_blankline_char = " "
let g:indent_blankline_char_highlight_list = ["IndentGuidesOdd"]
let g:indent_blankline_show_first_indent_level = v:false

execute 'source $VIMHOME/cfg/vimrc'
