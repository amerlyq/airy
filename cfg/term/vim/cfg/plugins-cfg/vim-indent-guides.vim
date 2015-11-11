" At the moment Terminal Vim only has basic support.
" So colors won't be autocalculated from your colorscheme.
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_exclude_filetypes = ['votl', 'iav_term']  " SEE RangerChooser

" Make 1-wide guide, don't works on Hard-Tabs
let g:indent_guides_guide_size = 1
let g:indent_guides_start_level = 2
let g:indent_guides_indent_levels = 20
let g:indent_guides_tab_guides = 0

let g:indent_guides_auto_colors = 0
let g:indent_guides_color_change_percent = 10
" Choose colors of solarized background for guides
au VimEnter,Colorscheme * hi! IndentGuidesOdd  ctermfg=8 ctermbg=0
au VimEnter,Colorscheme * hi! IndentGuidesEven ctermfg=8 ctermbg=0

let g:indent_guides_default_mapping = 0
nnoremap <unique> <Leader>tI :IndentGuidesToggle<CR>
