let $VIMHOME=fnamemodify(resolve(expand('<sfile>')), ':h')

let g:indent_blankline_char = "┊"
" let g:indent_blankline_char_highlight_list = ["IndentGuidesOdd"]
let g:indent_blankline_show_first_indent_level = v:false

lua << EOF
require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'onedark',
    component_separators = '|',
    section_separators = '',
    globalstatus = true,
  },
  sections = {
    lualine_b = {'diagnostics'},  -- 'branch', 'diff'
    lualine_c = {'buffers'},
    lualine_x = {'tabs', 'filetype'},  -- 'encoding', 'fileformat'
  },
}
EOF

execute 'source $VIMHOME/cfg/vimrc'

nnoremap <S-Tab> :RnvimrToggle<CR>
nnoremap <C-Tab> :RnvimrResize<CR>

" hi! Visual  guibg=#586e75 gui=None guifg=#002b36
hi! Visual  guibg=#839496 gui=None guifg=#002b36
hi! Whitespace  ctermfg=0 ctermbg=8 guifg=#073642 guibg=#002b36
