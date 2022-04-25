let $VIMHOME=fnamemodify(resolve(expand('<sfile>')), ':h')

let g:indent_blankline_char = " "
let g:indent_blankline_show_first_indent_level = v:false

lua << EOF
local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, 'lua/?.lua')
table.insert(runtime_path, 'lua/?/init.lua')
require 'plugins.lualine'
EOF

execute 'source $VIMHOME/cfg/vimrc'

nnoremap <S-Tab> :RnvimrToggle<CR>
nnoremap <C-Tab> :RnvimrResize<CR>

" hi! Visual  guibg=#586e75 gui=None guifg=#002b36
hi! Visual  cterm=None,nocombine ctermbg=242 guibg=#839496 gui=None,nocombine guifg=#002b36
hi! Whitespace  ctermfg=0 guifg=#093f4f
hi! IndentBlanklineChar  ctermfg=8 ctermbg=0 cterm=None guifg=#002b36 guibg=#072f3b gui=None
