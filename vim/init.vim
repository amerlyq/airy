let $VIMHOME=fnamemodify(resolve(expand('<sfile>')), ':h')

let g:indent_blankline_char = " "
let g:indent_blankline_show_first_indent_level = v:false

" hi! Visual  guibg=#586e75 gui=None guifg=#002b36
hi! Visual  cterm=None,nocombine ctermbg=242 guibg=#839496 gui=None,nocombine guifg=#002b36
hi! Whitespace  ctermfg=0 guifg=#093f4f
hi! IndentBlanklineChar  ctermfg=8 ctermbg=0 cterm=None guifg=#002b36 guibg=#072f3b gui=None

set shada='100,<0,s10,h

unlet $XDG_CONFIG_HOME
" let g:loaded_ranger = 0
" autocmd VimEnter set packpath=/@/airy/vim | lua require('plug.rnvimr') | packadd rnvimr

execute 'source $VIMHOME/cfg/vimrc'
