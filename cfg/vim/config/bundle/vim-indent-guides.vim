" At the moment Terminal Vim only has basic support.
" So colors won't be autocalculated from your colorscheme.
let g:indent_guides_enable_on_vim_startup = 1
let g:indent_guides_exclude_filetypes = ['votl']
let g:indent_guides_default_mapping = 0
nnoremap <silent> <Leader>tg <Plug>IndentGuidesToggle

" Make 1-wide guide, don't works on Hard-Tabs
let g:indent_guides_guide_size = 1
let g:indent_guides_start_level = 2

" Choose colors of solarized background for guides
let g:indent_guides_color_change_percent = 20

let g:indent_guides_auto_colors = 0
" autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg='#073642' ctermbg=0
" autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg='#073642' ctermbg=0
autocmd VimEnter,Colorscheme * highlight! link IndentGuidesOdd  LineNr
autocmd VimEnter,Colorscheme * highlight! link IndentGuidesEven LineNr
