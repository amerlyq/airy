" let g:airline_theme_patch_func = 'AirlineThemePatch'
" function! AirlineThemePatch(palette)
" if g:airline_theme == 'badwolf'
"   for colors in values(a:palette.inactive)
"     highlight clear airline_tabfill
"     "let colors[3] = 245
"   endfor
" endif
" endfunction

let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1

""Maybe it will reduce CPU load, not showing which lines are chaged
"(gitgutter, signify, etc)
let g:airline#extensions#hunks#enabled=0

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

